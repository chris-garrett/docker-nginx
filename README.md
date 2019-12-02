# docker-nginx

* Nginx image 1.17.6r0

## Versions
- nginx 1.17.6 (unprivileged) on alpine 
  - https://github.com/nginxinc/docker-nginx-unprivileged
  - https://hub.docker.com/r/nginxinc/nginx-unprivileged
- dockerize v0.6.1

## Usage

```docker run --rm -it -p 8080:8080 chrisgarrett/nginx:1.17.6r0```

## Credits

I used Andrew's Dockerfile as a guide for adding modsec

https://github.com/andrewnk/docker-alpine-nginx-modsec/blob/master/Dockerfile

