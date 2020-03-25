#!/bin/bash -e

if ! grep -q "Ubuntu 18.04" /etc/issue; then
    echo "This script is only compatible with Ubuntu 18.04"
    exit
fi

echo

PUBLIC_IP=$(curl --silent https://ipecho.net/plain)
read -p "Enter your domain or IP (or leave blank to use $PUBLIC_IP): " HTTP_HOST

if [ -z ${HTTP_HOST} ]; then
  HTTP_HOST=$PUBLIC_IP
fi

# Add repository and install WireGuard
add-apt-repository -y ppa:wireguard/wireguard
apt-get update
apt-get install -y wireguard

# Set DNS
echo nameserver 9.9.9.9 > /etc/resolv.conf

# Load modules
modprobe wireguard
modprobe iptable_nat
modprobe ip6table_nat

echo "wireguard" >> /etc/modules
echo "iptable_nat" >> /etc/modules
echo "ip6table_nat" >> /etc/modules

# Enable IP forwarding
sysctl -w net.ipv4.ip_forward=1
sysctl -w net.ipv6.conf.all.forwarding=1

sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/g' /etc/sysctl.conf
sed -i 's/#net.ipv6.conf.all.forwarding=1/net.ipv6.conf.all.forwarding=1/g' /etc/sysctl.conf

# Disable resolved
systemctl disable systemd-resolved
systemctl stop systemd-resolved

# Install packages to allow apt to use a repository over HTTPS
apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg-agent \
    software-properties-common

# Add Docker’s official GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

# Set up the stable repository
add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"

# Update apt and install the latest version of Docker Engine (CE) and containerd
apt-get update

apt-get install -y \
    docker-ce \
    docker-ce-cli \
    containerd.io

docker run -d \
    --name subspace \
    --restart always \
    --network host \
    --cap-add NET_ADMIN \
    --volume /usr/bin/wg:/usr/bin/wg \
    --volume /data:/data \
    --env SUBSPACE_HTTP_HOST=$HTTP_HOST \
    --env SUBSPACE_HTTP_INSECURE=true \
    --env SUBSPACE_LETSENCRYPT=false \
    simwood/subspace:latest

echo
echo "Done! Subspace should be available momentarily at http://$HTTP_HOST"
echo
