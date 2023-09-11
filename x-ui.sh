#!/bin/bash

print_red() {
    echo -e "\e[31m$1\e[0m"
}

print_green() {
    echo -e "\e[32m$1\e[0m"
}

print_progress() {
    local total=$1
    local current=$2
    local width=6
    local num_filled=$(( current * width / total ))
    local num_empty=$(( width - num_filled ))
    local filled=$(printf '⣿%.0s' $(seq 1 $num_filled))
    local empty=$(printf '⣀%.0s' $(seq 1 $num_empty))
    printf "✔ xui %s layers [%s%s] %sB/%sB\r" "$current" "$filled" "$empty" "$current" "$total"
}

print_red "Installing dependencies."
print_progress 6 1
apt-get update -qq > /dev/null
print_progress 6 2
apt-get install -y -qq ca-certificates curl gnupg vim > /dev/null

print_red "Installing Docker."
install -m 0755 -d /etc/apt/keyrings

print_progress 6 3
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo $VERSION_CODENAME) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

print_red "Installing Docker and plugins."
print_progress 6 4
apt-get update -qq > /dev/null
print_progress 6 5
apt-get install -y -qq docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin > /dev/null
systemctl enable docker

docker_version=$(docker --version)
print_red "$docker_version"

sleep 2
print_red "Installing Docker-compose."
print_progress 6 6
curl -sSL https://github.com/docker/compose/releases/download/v2.20.3/docker-compose-linux-x86_64 -o /usr/local/bin/docker-compose
ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

docker_compose_version=$(docker-compose --version)
print_red "$docker_compose_version"

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
ip_server=$(echo $SSH_CONNECTION | awk '{print $3}')
log_output=$(docker logs x-ui 2>&1 | grep "INFO - web server run http on")
PORT=$(echo "$log_output" | grep -oP '\[\:\:\]\:\K\d+')
print_red "---------------------------"
print_green "Panel running on ${ip_server}:${PORT}"
print_red "---------------------------"
