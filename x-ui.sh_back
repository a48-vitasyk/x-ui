#!/bin/bash

update_time_counter() {
    local task_name="$1"
    local total=$2
    local current=$3
    while true; do
        sleep 1
        print_progress "$task_name" "$total" "$current"
    done
}

print_progress() {
    local task_name="$1"
    local total=$2
    local current=$3
    local width=6
    local num_filled=$(( current * width / total ))
    local num_empty=$(( width - num_filled ))
    local filled=$(printf '\e[32m⣿%.0s\e[0m' $(seq 1 $num_filled))
    local empty=$(printf '⣀%.0s' $(seq 1 $num_empty))
    local elapsed_time=$(date +%s)
    local time_diff=$(( elapsed_time - start_time ))
    # Используем '\r' для возврата к началу строки
    printf "\r✔ %s [%s%s] %ss" "$task_name" "$filled" "$empty" "$time_diff"
}

print_red() {
    echo -e "\n\e[31m$1\e[0m"
}

print_green() {
    echo -e "\n\e[32m$1\e[0m"
}

start_time=$(date +%s)

if grep -q "CentOS" /etc/*release; then
    IS_CENTOS=true
    INSTALL_CMD="yum -y install"
else
    IS_CENTOS=false
    apt-get update > /dev/null
    INSTALL_CMD="apt-get install -y"
fi

if ! command -v curl &> /dev/null; then
    print_red "Installing curl ..."
    $INSTALL_CMD curl > /dev/null
fi

if ! command -v pv &> /dev/null; then
    print_red "Installing pv ..."
    $INSTALL_CMD pv > /dev/null 2>&1
fi

print_red "Installing dependencies."
echo
if $IS_CENTOS; then
    $INSTALL_CMD ca-certificates curl gnupg vim > /dev/null
else
    update_time_counter "Installing dependencies" 6 1 &
    pid1=$!
    apt-get update -qq > /dev/null
    apt-get install -y -qq ca-certificates curl gnupg vim > /dev/null
    kill $pid1
fi
print_red "\nInstalling Docker."
if ! command -v docker &> /dev/null; then
    if $IS_CENTOS; then
        # Instructions for CentOS
        yum install -y yum-utils > /dev/null  2>&1
        yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo > /dev/null  2>&1
        yum install -y docker-ce docker-ce-cli containerd.io > /dev/null  2>&1
        systemctl start docker > /dev/null  2>&1
        systemctl enable docker > /dev/null  2>&1
    else
        # Instructions for Debian-based systems
        update_time_counter "Installing Docker" 6 3 &
        pid2=$!
        install -m 0755 -d /etc/apt/keyrings
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --yes --dearmor -o /etc/apt/keyrings/docker.gpg > /dev/null
        kill $pid2

        update_time_counter "Installing Docker" 6 4 &
        pid3=$!
        chmod a+r /etc/apt/keyrings/docker.gpg
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo $VERSION_CODENAME) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
        kill $pid3

        print_red "Installing Docker plugins."
        update_time_counter "Installing Docker plugins" 6 5 &
        pid4=$!
        apt-get update -qq > /dev/null
        apt-get install -y -qq docker-ce docker-ce-cli containerd.io > /dev/null
        echo
        systemctl enable docker > /dev/null 2>&1
        kill $pid4
    fi
else
    docker_version=$(docker --version)
    print_red "\n$docker_version"
fi

print_red "Installing Docker-compose."
if ! command -v docker-compose &> /dev/null; then
    update_time_counter "Installing Docker-compose" 6 6 &
    pid5=$!
    sudo curl -sSL https://github.com/docker/compose/releases/download/v2.20.3/docker-compose-linux-x86_64 -o /usr/local/bin/docker-compose
    sudo ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    kill $pid5
else
    docker_compose_version=$(docker-compose --version)
    print_red "\n$docker_compose_version"
fi


docker_compose_version=$(docker-compose --version)
print_red "$docker_compose_version"

print_green "Finalizing installation."
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

sleep 3
ip_server=$(echo $SSH_CONNECTION | awk '{print $3}')
log_output=$(docker logs x-ui 2>&1 | grep "INFO - web server run http on")
PORT=$(echo "$log_output" | grep -oP '\[\:\:\]\:\K\d+')
print_red "\n------------------------------------"
print_green "Panel running on ${ip_server}:${PORT}"
print_red "------------------------------------"

if grep -q "CentOS" /etc/os-release; then
    # Проверяем, существует ли зона "docker"
    if firewall-cmd --get-zones | grep -qw "docker"; then
        firewall-cmd --permanent --zone=docker --add-port=${PORT}/tcp  > /dev/null
    else
        firewall-cmd --permanent --zone=public --add-port=${PORT}/tcp  > /dev/null
    fi
    systemctl stop firewalld  > /dev/null
fi
#wget -qO- https://raw.githubusercontent.com/a48-vitasyk/x-ui/main/x-ui.sh | bash