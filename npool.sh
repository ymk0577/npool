#!/bin/bash

# Stop
old_process=$(ps -ef | grep npool | grep -v grep |wc -l)
if [[ "$old_process" == "1" ]];then
    systemctl stop npool.service
fi
old_process=$(ps -ef | grep nknd | grep -v grep |wc -l)
if [[ "$old_process" == "1" ]];then
    if test -f "/etc/systemd/system/nkn-commercial.service"
    then
        systemctl stop nkn-commercial.service
    else
        ps -ef|grep nknd|grep -v grep|awk '{print $2}'|xargs kill -9
    fi
fi

# Check if user is root
if [ $(id -u) != "0" ]; then
    echo "Error: You must be root to run this script, please use root to install"
    exit 1
fi

# Check appKey
app_key=$1
if [ ! -n "$app_key" ]; then
    echo "Error: missing appKey"
    exit 1
fi

pruning_mode=$2

# Check arch
get_arch=`arch`
if [[ $get_arch =~ "x86_64" ]];then
    arch_type="amd64"
elif [[ $get_arch =~ "aarch64" ]];then
    arch_type="arm64"
else
    echo "Error: Only supports amd64 and arm64 architecture machines"
    exit 1
fi

cur_dir=$(pwd)

# Download Package
Download()
{
    echo "Start Download......"
    if test -f "config.json"
    then
        wget -c -t 5 --quiet "https://download.npool.io/linux-${arch_type}.tar.gz" && tar zxvf "linux-${arch_type}.tar.gz" && mv "linux-${arch_type}/npool" ./ && rm -rf "linux-${arch_type}" && rm -f nknd
       if test -f "wallet.json"
       then
            start_shell="${cur_dir}/npool --appkey ${app_key} --wallet ${cur_dir}/wallet.json --password-file ${cur_dir}/wallet.pswd"
       else
            start_shell="${cur_dir}/npool --appkey ${app_key}"
       fi
        work_dir="${cur_dir}"
    else
        wget -c -t 5 --quiet  "https://download.npool.io/linux-${arch_type}.tar.gz" && tar zxvf "linux-${arch_type}.tar.gz"
        start_shell="${cur_dir}/linux-${arch_type}/npool --appkey ${app_key}"
        work_dir="${cur_dir}/linux-${arch_type}"
    fi
    if [[ "$pruning_mode" == "no-pruning" ]]
    then
	start_shell="${start_shell} --pruning none"
    fi
}

# Install
Install_NPool()
{
    echo "Start Install......"
    cat > /etc/systemd/system/npool.service <<End-of-file
[Unit]
Description=npool server

[Service]
Type=simple
WorkingDirectory=${work_dir}
ExecStart=${start_shell}
Restart=always
RestartSec=20
StartLimitInterval=0

[Install]
WantedBy=multi-user.target
End-of-file
    systemctl daemon-reload
    systemctl enable npool.service
    systemctl start npool.service
    echo "Success."
    rm linux-${arch_type}.tar.gz
    rm $0
}
if command -v apt-get > /dev/null 2>&1; then
	echo "Installing necessary libraries..."
	echo "---------------------------"
	apt-get install -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" -y --force-yes make curl git unzip whois
	apt-get install -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" -y --force-yes unzip jq
	ufw allow 30001:30005/tcp > /dev/null 2>&1
	ufw allow 30001:30005/udp > /dev/null 2>&1
	ufw allow 22 > /dev/null 2>&1
	ufw allow 80 > /dev/null 2>&1
	ufw allow 443 > /dev/null 2>&1
	ufw allow 32768:65535/tcp > /dev/null 2>&1
	ufw allow 32768:65535/udp > /dev/null 2>&1
fi

# Log file limit
if grep -q "SystemMaxUse=100M" /etc/systemd/journald.conf; then
    echo "File contains the string 'SystemMaxUse=100M'"
else
    echo "SystemMaxUse=100M" >> /etc/systemd/journald.conf
fi
if grep -q "ForwardToSyslog=no" /etc/systemd/journald.conf; then
    echo "File contains the string 'ForwardToSyslog=no'"
else
    echo "ForwardToSyslog=no" >> /etc/systemd/journald.conf
    systemctl restart systemd-journald.service
fi
if grep -q "MaxFileSize 100M" /etc/rsyslog.conf; then
    echo "File contains the string 'MaxFileSize 100M'"
else
    echo "\$MaxFileSize 100M" >> /etc/rsyslog.conf
    systemctl restart rsyslog
fi
ufw logging off
journalctl --disk-usage
ls -lh /var/log/syslog

# Start downloading and installing Npool
Download
Install_NPool
