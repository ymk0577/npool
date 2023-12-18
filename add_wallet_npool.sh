#!/bin/bash

# Stop
old_process=$(ps -ef | grep npool | grep -v grep |wc -l)
if [[ "$old_process" == "1" ]];then
    systemctl stop npool.service
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

cur_dir=$(cd dirname $0; pwd)

# Download Package
Download()
{
    echo "Start Check......"
    if test -f "npool"
    then
       if test -f "wallet.json" && test -f "wallet.pswd"
       then
            start_shell="${cur_dir}/npool --appkey ${app_key} --wallet ${cur_dir}/wallet.json --password-file ${cur_dir}/wallet.pswd"
       else
             echo "Error: missing wallet file"
             exit 1
       fi
        work_dir="${cur_dir}"
    else
        echo "Error: directory error"
        exit 1
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
    systemctl restart npool.service
    echo "Success."
}

Download
Install_NPool
