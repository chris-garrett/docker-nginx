FROM nginxinc/nginx-unprivileged:1.17.6-alpine as build_modsecurity

USER root

RUN apk add --no-cache --virtual .build-deps \
        gcc \
        libc-dev \
        make \
        openssl-dev \
        pcre-dev \
        zlib-dev \
        linux-headers \
        curl \
        gnupg \
        libxslt-dev \
        gd-dev \
        perl-dev \
    && apk add --no-cache --virtual .libmodsecurity-deps \
        pcre-dev \
        libxml2-dev \
        git \
        libtool \
        automake \
        autoconf \
        g++ \
        flex \
        bison \
        yajl-dev \
    # Add runtime dependencies that should not be removed
    && apk add --no-cache \
        geoip \
        geoip-dev \
        yajl \
        libstdc++ \
        git \
        sed \
        libmaxminddb-dev

WORKDIR /opt/ModSecurity

RUN echo "Installing ModSec Library" && \
    git clone -b v3/master --single-branch https://github.com/SpiderLabs/ModSecurity . && \
    git submodule init && \
    git submodule update && \
    ./build.sh && \
    ./configure && make && make install

WORKDIR /opt

RUN echo 'Installing ModSec - Nginx connector' && \
    git clone --depth 1 https://github.com/SpiderLabs/ModSecurity-nginx.git && \
    wget http://nginx.org/download/nginx-1.17.6.tar.gz && \
    tar zxvf nginx-1.17.6.tar.gz

WORKDIR /opt/GeoIP

RUN git clone -b master --single-branch https://github.com/leev/ngx_http_geoip2_module.git .

WORKDIR /opt/nginx-1.17.6

RUN ./configure --with-compat --add-dynamic-module=../ModSecurity-nginx  --add-dynamic-module=../GeoIP && \
    make modules && \
    cp objs/ngx_http_modsecurity_module.so objs/ngx_http_geoip2_module.so /etc/nginx/modules && \
    rm -f /usr/local/modsecurity/lib/libmodsecurity.a /usr/local/modsecurity/lib/libmodsecurity.la

WORKDIR /opt

RUN echo "Begin installing ModSec OWASP Rules" && \
    git clone -b v3.2/master https://github.com/SpiderLabs/owasp-modsecurity-crs && \
    mv owasp-modsecurity-crs/ /usr/local/

RUN mkdir /etc/nginx/modsec && \
    rm -fr /etc/nginx/conf.d/ && \
    rm -fr /etc/nginx/nginx.conf

COPY conf/nginx/ /etc/nginx/
COPY conf/modsec/ /etc/nginx/modsec/
COPY conf/owasp/ /usr/local/owasp-modsecurity-crs/
#COPY errors /usr/share/nginx/errors

RUN mkdir -p /etc/nginx/geoip && \
    wget http://geolite.maxmind.com/download/geoip/database/GeoLite2-City.tar.gz && \
    wget http://geolite.maxmind.com/download/geoip/database/GeoLite2-Country.tar.gz && \
    tar -xvzf GeoLite2-City.tar.gz --strip-components=1 && \
    tar -xvzf GeoLite2-Country.tar.gz --strip-components=1 && \
    mv *.mmdb /etc/nginx/geoip/

RUN chown -R nginx:nginx /usr/share/nginx /etc/nginx


FROM nginxinc/nginx-unprivileged:1.17.6-alpine
MAINTAINER Chris Garrett (https://github.com/chris-garrett/docker-nginx)
LABEL description="Nginx image 1.17.6"

USER root

COPY ./vimrc /home/nginx/.vimrc

RUN mkdir /etc/nginx/modsec && \
    rm -fr /etc/nginx/conf.d/ && \
    rm -fr /etc/nginx/nginx.conf

# Copy nginx config from the intermediate container
COPY --from=build_modsecurity /etc/nginx/. /etc/nginx/
# Copy the /usr/local folder form the intermediate container (owasp-modsecurty-crs, modsecurity libs)
COPY --from=build_modsecurity /usr/local/. /usr/local/.
#COPY --from=build_modsecurity /usr/share/nginx/errors /usr/share/nginx/errors
COPY --from=build_modsecurity /usr/lib/nginx/modules/. /usr/lib/nginx/modules/

RUN apk upgrade --no-cache \
  && apk --no-cache add -U \
    ca-certificates \
    openssl \
  && update-ca-certificates \
  && apk --no-cache add -U \
    yajl \
    libstdc++ \
    libmaxminddb-dev \
    tzdata \  
    vim \
    wget \
    curl \
  && wget https://github.com/jwilder/dockerize/releases/download/v0.6.1/dockerize-alpine-linux-amd64-v0.6.1.tar.gz \
  && tar -C /usr/local/bin -xzvf dockerize-alpine-linux-amd64-v0.6.1.tar.gz \
  && rm dockerize-alpine-linux-amd64-v0.6.1.tar.gz \
  && chown nginx:nginx /home/nginx/.vimrc /usr/share/nginx /etc/nginx \
  && ln -sf /usr/bin/vim /usr/bin/vi 

# From nginx:unprivileged repo
# nginx user must own the cache directory to write cache
RUN chown -R 101:0 /var/cache/nginx /etc/nginx/conf.d \
    && chmod -R g+w /var/cache/nginx /etc/nginx/conf.d

RUN mkdir -p /var/log/modsec \
  && chown -R nginx:nginx /var/log/modsec

USER nginx
WORKDIR /usr/share/nginx/html
