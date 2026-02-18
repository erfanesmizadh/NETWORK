#!/bin/bash

GREEN="\e[32m"
RED="\e[31m"
YELLOW="\e[33m"
BLUE="\e[36m"
NC="\e[0m"

WG="wg0"

if [[ $EUID -ne 0 ]]; then
 echo -e "${RED}Run as root${NC}"
 exit 1
fi

banner(){
clear
echo -e "${BLUE}"
cat <<EOF
███╗   ███╗ ██████╗ ███╗   ██╗███████╗████████╗███████╗██████╗
████╗ ████║██╔═══██╗████╗  ██║██╔════╝╚══██╔══╝██╔════╝██╔══██╗
██╔████╔██║██║   ██║██╔██╗ ██║███████╗   ██║   █████╗  ██████╔╝
██║╚██╔╝██║██║   ██║██║╚██╗██║╚════██║   ██║   ██╔══╝  ██╔══██╗
██║ ╚═╝ ██║╚██████╔╝██║ ╚████║███████║   ██║   ███████╗██║  ██║

 MONSTER LAYER5 PRIVATE NETWORK
EOF
echo -e "${NC}"
}

pause(){ read -p "Press Enter..."; }

install_all(){

echo -e "${YELLOW}Installing packages...${NC}"

apt update -y
apt install wireguard qrencode curl wget git -y

echo -e "${GREEN}Installed${NC}"
}

enable_bbr(){

modprobe tcp_bbr
echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
sysctl -p

echo -e "${GREEN}BBR Enabled${NC}"
}

generate_keys(){

mkdir -p /etc/wireguard

wg genkey | tee /etc/wireguard/privatekey | wg pubkey > /etc/wireguard/publickey

echo -e "${GREEN}Your Public Key:${NC}"
cat /etc/wireguard/publickey
}

create_config(){

read -p "Local Private IP (example 10.66.0.1): " LOCALIP
read -p "Peer Public Key: " PEERKEY
read -p "Peer Public IP: " PEERIP
read -p "Port [51820]: " PORT
PORT=${PORT:-51820}

PRIVATE=$(cat /etc/wireguard/privatekey)

cat <<EOF > /etc/wireguard/${WG}.conf
[Interface]
PrivateKey = $PRIVATE
Address = $LOCALIP/24
ListenPort = $PORT
PostUp = sysctl -w net.ipv4.ip_forward=1

[Peer]
PublicKey = $PEERKEY
AllowedIPs = 10.66.0.0/24
Endpoint = $PEERIP:$PORT
PersistentKeepalive = 25
EOF

echo -e "${GREEN}Config created${NC}"
}

start_network(){

wg-quick up $WG
systemctl enable wg-quick@$WG

echo -e "${GREEN}Private Layer5 Network Started${NC}"
}

status_network(){

wg show
}

install_udp2raw(){

echo -e "${YELLOW}Installing udp2raw DPI bypass...${NC}"

wget https://github.com/wangyu-/udp2raw-tunnel/releases/download/20230206.0/udp2raw_binaries.tar.gz
tar -xvf udp2raw_binaries.tar.gz
cp udp2raw_*_amd64 /usr/local/bin/udp2raw
chmod +x /usr/local/bin/udp2raw

echo -e "${GREEN}udp2raw installed${NC}"
}

menu(){

banner

echo -e "${GREEN}
[1] Install Requirements
[2] Generate WireGuard Keys
[3] Create Private Layer5 Network
[4] Start Network
[5] Show Status
[6] Enable TCP BBR
[7] Install UDP2RAW (Anti DPI)
[0] Exit${NC}
"

read -p "Select: " opt

case $opt in
1) install_all ;;
2) generate_keys ;;
3) create_config ;;
4) start_network ;;
5) status_network ;;
6) enable_bbr ;;
7) install_udp2raw ;;
0) exit ;;
*) echo "Invalid";;
esac

pause
menu
}

menu
