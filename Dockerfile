FROM vaultwarden/server:latest

MAINTAINER wuyang@drwuyang.top

COPY bfsu.bullseye.source.list /tmp/
COPY *.sh /
COPY nginx/* /tmp/

RUN mv -f /tmp/bfsu.bullseye.source.list /etc/apt/sources.list && \
    apt update -yy && \
    apt upgrade -yy && \
    apt install -qyy apt-utils && \
    apt install -qyy nginx curl iputils-ping jq wget procps && \
    apt autoremove -yy && \
    apt autoclean -yy && \
    mv -f /tmp/nginx.conf /etc/nginx/nginx.conf && \
    mv -f /tmp/8080_for_test.conf /etc/nginx/sites-enabled/default && \
    mv -f /tmp/index.html /var/www/html/index.html && \
    cd / && \
    wget -O frp.tar.gz "$(curl -s https://api.github.com/repos/fatedier/frp/releases/latest |jq -r ".assets[] | select(.name | test(\"linux_amd6\")) | .browser_download_url")" && \
    mkdir ./frp && \
    tar -zxvf frp.tar.gz -C ./frp --strip-components 1 && \
    rm -rf /frp/frps.ini /frp/frps_full.ini /frp/frpc_full.ini /frp/frps && \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/* && \
    mkdir -p /nginx-conf && \
    mkdir -p /log /ssl && \
    chmod +x /*.sh

ENV REVERSE_PROXY_CONFIG="443_reverse_proxy.conf"
ENV FULLCHAIN="/ssl/fullchain.pem"
ENV PRIVATE="/ssl/privkey.pem"
ENV FRPC_CONFIG="frpc.ini"
ENV FRPC_LOG="frpc.log"

WORKDIR /

EXPOSE 80
EXPOSE 443
EXPOSE 8080


HEALTHCHECK --interval=60s --timeout=10s CMD ["/healthcheck.sh"]
CMD ["/init.sh"]
