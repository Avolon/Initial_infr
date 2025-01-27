#!/bin/bash

# Перечитываем пакеты и обновляем ОС
apt-get update && apt-get upgrade -y

# Устнавливаем terraform и terragrunt с учетом яндекс зеркала для работы в условиях блокировок - делаем исполняемыми бинарные файлы
chmod +x /home/ubuntu/terraform      
chmod +x /home/ubuntu/terragrunt
mv /home/ubuntu/terraform /bin/terraform
mv /home/ubuntu/terragrunt /bin/terragrunt
cp /home/ubuntu/.terraformrc /home/ubuntu/.terraformrc
mv /home/ubuntu/.terraformrc /root/.terraformrc

# Ставим предварительные пакеты и зависимости для дальнейших установок утилит, ставим git и синхронизируем время на сервисной ноде
apt-get install -y git curl ca-certificates curl gnupg lsb-release gnome-terminal apt-transport-https gnupg-agent software-properties-common chrony tzdata
timedatectl set-timezone Europe/Moscow && systemctl start chrony && systemctl enable chrony

# Ставим docker, docker compose
curl -fsSL https://get.docker.com | sh
usermod -aG docker $USER
apt-get install docker-ce docker-ce-cli containerd.io docker-compose-plugin -y
systemctl enable docker.service && systemctl enable containerd.service && systemctl start docker.service && sudo systemctl start containerd.service

# Ставим jq, pip и ansible
add-apt-repository ppa:deadsnakes/ppa -y
apt install python3-pip -y
apt-get install jq ansible -y

# Установка kubeadm kubectl
# Ставим публичный ключ Google Cloud.
# Добавляем Kubernetes репозиторий и перечитываем их:
curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-archive-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list 
apt-get update

# Устанавливаем и замораживаем версию утилит при последующих обновлениях через пакетный менеджер:
apt-get install -y kubeadm kubectl
apt-mark hold kubeadm kubectl

# Установка helm
# Ставим ключ и репозиторий:
curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list

# Перечитываем репозитории и ставим helm
apt-get update 
apt-get install helm -y

# Установка gitlab-runner
# Ставим официальный репозиторий gitlab-runner и перечитываем списки репозиторий
curl -L "https://packages.gitlab.com/install/repositories/runner/gitlab-runner/script.deb.sh" | sudo bash 
apt-get update

# Установка и запуск gitlab-runner
apt-get install gitlab-runner -y
systemctl enable gitlab-runner --now

echo -e "Сервисная нода готова к управлению кластером k8s. Приступаем к подготовке к развёртывнию кластера."
sleep 35

# Клонируем репозитории для установки k8s кластера с помощью kubespray
cd /opt/
git clone https://github.com/avolon/kubernetes_setup.git
cd kubernetes_setup/
git clone https://github.com/avolon/kubespray
pip3 install -r /opt/kubernetes_setup/kubespray/requirements-2.9.txt
sleep 25

# Даём нужные разрешения, подкладываем ключи
chmod +x /opt/kubernetes_setup/cluster_install.sh
chmod +x /opt/kubernetes_setup/cluster_destroy.sh
chmod +x /opt/kubernetes_setup/terraform/generate_credentials_velero.sh
chmod +x /opt/kubernetes_setup/terraform/generate_etc_hosts.sh
chmod +x /opt/kubernetes_setup/terraform/generate_inventory.sh
mv /home/ubuntu/private.variables.tf /opt/kubernetes_setup/terraform/private.variables.tf
cp /home/ubuntu/avolon-skillfactory.pub /home/ubuntu/.ssh/avolon-skillfactory.pub
cp /home/ubuntu/avolon-skillfactory /home/ubuntu/.ssh/avolon-skillfactory
mv /home/ubuntu/avolon-skillfactory.pub /root/.ssh/avolon-skillfactory.pub
mv /home/ubuntu/avolon-skillfactory /root/.ssh/avolon-skillfactory
echo "private_key_file = /home/ubuntu/.ssh/avolon-skillfactory.pub" >> /etc/ansible/ansible.cfg
echo "private_key_file = /home/ubuntu/.ssh/avolon-skillfactory.pub" >> /opt/kubernetes_setup/kubespray/ansible.cfg
chmod 700 /home/ubuntu/.ssh/
chmod 700 /root/.ssh/
chmod 600 /home/ubuntu/.ssh/avolon-skillfactory
chown -R ubuntu:ubuntu /home/ubuntu/.ssh/avolon-skillfactory
chmod 600 /root/.ssh/avolon-skillfactory
chown -R root:root /root/.ssh/avolon-skillfactory
chmod 644 /home/ubuntu/.ssh/avolon-skillfactory.pub
chown -R ubuntu:ubuntu /home/ubuntu/.ssh/avolon-skillfactory.pub
chmod 644 /root/.ssh/avolon-skillfactory.pub
chown -R root:root /root/.ssh/avolon-skillfactory.pub
apt-get autoremove -y
apt-get autoclean -y

# Поверяем как установились утилиты и их версии: ansible, terraform, terragrunt, jq, docker, docker-compose, git, gitlab-runner, kubeadm, kubectl, helm
echo -e " "
echo -e "Подготовка сервера srv закончена!"
echo -e " "
echo -e "Установились следующие утилиты:"
echo -e " "
echo -e "=========================== Версия ansible =================================="
echo -e " "
ansible --version
echo -e " "
echo -e "=========================== Версия python3 =================================="
echo -e " "
python3 --version
echo -e " "
echo -e "========================== Версия terraform ================================="
terraform --version
echo -e " "
echo -e "========================== Версия terragrunt ================================"
terragrunt --version
echo -e " "
echo -e "============================== Версия jq ===================================="
jq --version
echo -e " "
echo -e "============================ Версия docker =================================="
docker --version
echo -e " "
echo -e "======================== Версия docker-compose =============================="
docker compose version
echo -e " "
echo -e "============================== Версия git ==================================="
git --version
echo -e " "
echo -e "======================== Версия gitlab-runner ==============================="
gitlab-runner --version
echo -e " "
echo -e "========================== Версия kubeadm ==================================="
kubeadm version
echo -e " "
echo -e "=========================== Версия kubectl =================================="
kubectl version
echo -e " "
echo -e "============================= Версия helm ==================================="
helm version
echo -e " "
echo -e "Необходимые пакеты: ansible,terraform, terragrunt, jq, docker, docker-compose, git, gitlab-runner, kubeadm, kubectl, helm установлены!"
echo -e "Подготовка к развёртыванию кластера k8s закончена успешно."
echo -e "Раскомментировать для автоматического каскадной установки кластера после создания сервисной норды."
echo -e "Иначе подключиться к сервисной ноде по ssh и запустить скрипт установки k8s кластера в ручную командой ниже:"
echo -e "/opt/kubernetes_setup/cluster_install.sh"
sleep 45


# Раскомментировать для автоматического каскадной установки кластера после создания сервисной норды.
# Иначе подключиться к сервисной ноде по ssh и запустить скрипт установки k8s кластера в ручную командой ниже:
#/opt/kubernetes_setup/cluster_install.sh
