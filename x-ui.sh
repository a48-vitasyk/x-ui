#!/bin/bash

print_red() {
    echo -e "\e[31m$1\e[0m"
}

print_green() {
    echo -e "\e[32m$1\e[0m"
}

apt-get update -qq > /dev/null
apt-get install -y -qq ca-certificates curl gnupg vim > /dev/null

install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo $VERSION_CODENAME) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update -qq > /dev/null
apt-get install -y -qq docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin > /dev/null
systemctl enable docker

curl -SL https://github.com/docker/compose/releases/download/v2.20.3/docker-compose-linux-x86_64 -o /usr/local/bin/docker-compose
ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

docker_version=$(docker --version)
docker_compose_version=$(docker-compose --version)
print_red "Установленная версия Docker: $docker_version"
print_red "Установленная версия Docker Compose: $docker_compose_version"

mkdir -p /home/x-ui
cat <<EOL > /home/x-ui/docker-compose.yaml
version: "3.9"
services:
  xui:
    image: alireza7/x-ui
    container_name: x-ui
    volumes:
      - $PWD/db/:/etc/x-ui/
      - $PWD/cert/:/root/cert/
    environment:
      XRAY_VMESS_AEAD_FORCED: "false"
    tty: true
    network_mode: host
    restart: unless-stopped
EOL

cd /home/x-ui
docker-compose up -d

sleep 5
log_output=$(docker logs x-ui 2>&1 | grep "INFO - web server run http on")
print_green "$log_output"
