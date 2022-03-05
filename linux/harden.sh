#!/bin/bash

check_root() {
    if [ "$UID" -a "$EUID" != 0 ]; then
        echo "got r00t?"
        exit 1
    fi
}

remove_chrontab() {
    chrontab -r $USER
}   

stop_services() {
    read -p "Stop sshd? (Y/n) " sshd_status
    if [ $sshd_status == "Y" ]; then
        systemctl stop sshd 2> /dev/null
        service sshd stop 2> /dev/null
    fi
}

create_new_admin() {
    useradd -c "CCDC" -d /ccdc/cyber -G wheel -u 777 ccdc
}

install_updates() {
    yum -y install update 2> /dev/null
    yum -y install upgrade 2> /dev/null
    yum -y install git 2> /dev/null
    apt -y install update 2> /dev/null
    apt -y install upgrade 2> /dev/null
    apt -y install git 2> /dev/null
}

set_dns() {
    sh -c 'echo "nameserver 8.8.8.8"' > /etc/resolv.conf
}


main() {
    check_root
    remove_chrontab
    set_dns
    install_updates
    stop_services
    create_new_admin

}

main
