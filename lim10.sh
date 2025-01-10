#!/bin/bash

show_help () {
    echo "Usage:"
    echo "  ./lim10.sh -b=5m -i=eth1"
    echo "  This will limit the BW on eth1 to 5Mbit"
    echo "  ./lim10.sh -b=512k -i=eth0"
    echo "  This will limit the BW on eth1 to 512kbit"
    echo "  ./lim10.sh -d -i=eth0"
    echo "  This will remove BW limit on eth0"
}

# Проверка на наличие обязательных параметров
if [ $# -eq 0 ]; then
    show_help
    exit 0
fi

# Функция удаления ограничения
del_limit() {
    if [ -n "$I_VALUE" ]; then
        tc qdisc del dev ${I_VALUE} root
    fi
}

# Чтение аргументов
for arg in "$@"; do
    case $arg in
        -b=*)
            B_VALUE="${arg#*=}"
            ;;
        -i=*)
            I_VALUE="${arg#*=}"
            ;;
        -d)
            del_limit
            exit 0
            ;;
        *)
            show_help
            exit 1
            ;;
    esac
done

# Проверка на наличие значений для параметров
if [ -z "$B_VALUE" ] || [ -z "$I_VALUE" ]; then
    echo "Error: Both bandwidth (-b) and interface (-i) must be specified."
    exit 1
fi

echo "BW limit value is $B_VALUE"
echo "Interface name is $I_VALUE"

# Установка ограничения
set_limit() {
    del_limit
    tc qdisc add dev ${I_VALUE} root handle 1: htb default 10
    tc class add dev ${I_VALUE} parent 1: classid 1:10 htb rate ${B_VALUE}bit ceil ${B_VALUE}bit
    # Пример корректного фильтра для ограничения трафика (для всего трафика):
    tc filter add dev ${I_VALUE} protocol ip parent 1:0 prio 1 u32 match ip dst 0.0.0.0/0 flowid 1:10
}

set_limit
