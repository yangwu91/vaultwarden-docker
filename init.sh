#!/bin/sh

set -u

# Init:
export NGINX_V=$( (/usr/sbin/nginx -v 2>&1) | grep -o "[0-9]*\.[0-9]*\.[0-9]*")
export FRP_V=$(/frp/frpc --version)
export VAULT_V=$(/vaultwarden --version | grep -o "[0-9]*\.[0-9]*\.[0-9]*")
sed -i -e "s/Nginx_X.X.X/Nginx_${NGINX_V}/g" \
    -e "s/Frp_X.X.X/Frp_${FRP_V}/g" \
    -e "s/Vaultwarden_X.X.X/Vaultwarden_${VAULT_V}/g" \
    /var/www/html/index.html


# Start and configure the nginx:
if [ ! -r /nginx-conf/${REVERSE_PROXY_CONFIG} ]; then
    mv -f /tmp/443_reverse_proxy.conf.1 /nginx-conf/${REVERSE_PROXY_CONFIG}.1
    mv -f /tmp/443_reverse_proxy.conf.2 /nginx-conf/${REVERSE_PROXY_CONFIG}.2
    for IP in `curl --silent https://www.cloudflare.com/ips-v4`; do
        echo "    set_real_ip_from $IP;" >> /nginx-conf/${REVERSE_PROXY_CONFIG}.1
    done
    for IP in `curl --silent https://www.cloudflare.com/ips-v6`; do
        echo "    set_real_ip_from $IP;" >> /nginx-conf/${REVERSE_PROXY_CONFIG}.1
    done
    cat /nginx-conf/${REVERSE_PROXY_CONFIG}.1 /nginx-conf/${REVERSE_PROXY_CONFIG}.2 > /nginx-conf/${REVERSE_PROXY_CONFIG}
    rm /nginx-conf/${REVERSE_PROXY_CONFIG}.1 /nginx-conf/${REVERSE_PROXY_CONFIG}.2
    chmod 666 /nginx-conf/${REVERSE_PROXY_CONFIG}
    if [ -r ${FULLCHAIN} ] && [ -r ${PRIVATE} ]; then
        sed -i -e "s,ssl_certificate /ssl/fullchain.pem;,ssl_certificate ${FULLCHAIN};,g" \
            -e "s,ssl_certificate_key /ssl/privkey.pem;,ssl_certificate_key ${PRIVATE};,g" \
            /nginx-conf/${REVERSE_PROXY_CONFIG}
    else
        echo "WARNING: The cert file ${FULLCHAIN} or ${PRIVATE} does not exsit."
    fi
fi
/usr/sbin/nginx


# Start the frpc:
/frp/frpc -c /frp/${FRPC_CONFIG} > /log/${FRPC_LOG} 2>&1 &


## Watchdog for nginx and frpc:
#watchdog(){
#    while true; do
#        ps -ef | grep "defunct" | awk '{print $3}' | sort | uniq | xargs kill -9
#        ps -ef | grep "/usr/sbin/nginx" | grep -v "grep" > /dev/null 2>&1
#        if [ "$?" != "0" ]; then
#            /usr/sbin/nginx
#        fi
#        ps -ef | grep "/frp/frpc" | grep -v "grep" > /dev/null 2>&1
#        if [ "$?" != "0" ]; then
#            /frp/frpc -c /frp/${FRPC_CONFIG} > /log/${FRPC_LOG} 2>&1 &
#        fi
#        /bin/sleep 300
#    done
#}
#watchdog &


# Copied from https://github.com/dani-garcia/vaultwarden/blob/main/docker/start.sh
if [ -r /etc/vaultwarden.sh ]; then
    . /etc/vaultwarden.sh
elif [ -r /etc/bitwarden_rs.sh ]; then
    echo "### You are using the old /etc/bitwarden_rs.sh script, please migrate to /etc/vaultwarden.sh ###"
    . /etc/bitwarden_rs.sh
fi

if [ -d /etc/vaultwarden.d ]; then
    for f in /etc/vaultwarden.d/*.sh; do
        if [ -r "${f}" ]; then
            . "${f}"
        fi
    done
elif [ -d /etc/bitwarden_rs.d ]; then
    echo "### You are using the old /etc/bitwarden_rs.d script directory, please migrate to /etc/vaultwarden.d ###"
    for f in /etc/bitwarden_rs.d/*.sh; do
        if [ -r "${f}" ]; then
            . "${f}"
        fi
    done
fi

exec /vaultwarden "${@}"
