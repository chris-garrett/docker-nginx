FROM nginx:1.10-alpine
MAINTAINER Chris Garrett (https://github.com/chris-garrett/docker-nginx)
LABEL description="Nginx image 1.10"

RUN apk --no-cache add -U ca-certificates openssl && update-ca-certificates
RUN apk --no-cache add -U \
  bash \
  vim \
  wget \
  curl

ARG DOCKERIZE_VERSION=v0.3.0
RUN wget https://github.com/jwilder/dockerize/releases/download/$DOCKERIZE_VERSION/dockerize-linux-amd64-$DOCKERIZE_VERSION.tar.gz \
    && tar -C /usr/local/bin -xzvf dockerize-linux-amd64-$DOCKERIZE_VERSION.tar.gz \
    && rm dockerize-linux-amd64-$DOCKERIZE_VERSION.tar.gz

COPY ./bash_aliases /home/nginx/.bashrc
COPY ./vimrc /home/nginx/.vimrc
RUN chown nginx:nginx /home/nginx/.bashrc /home/nginx/.vimrc \
  && ln -sf /usr/bin/vim /usr/bin/vi

USER nginx
