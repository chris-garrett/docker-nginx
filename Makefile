export NGINX_VERSION=1.17.6
export DOCKERIZE_VERSION=v0.6.1
export IMAGE_VERSION=${NGINX_VERSION}r0
export IMAGE_NAME=chrisgarrett/nginx


all: build

prep:
	envsubst < ./templates/Dockerfile.template > Dockerfile
	envsubst < ./templates/README.md.template > README.md

build: prep
	docker build --rm=true -t ${IMAGE_NAME}:${IMAGE_VERSION} .

run:
	docker run --rm -it -p 8080:8080 ${IMAGE_NAME}:${IMAGE_VERSION}

sh:
	docker run --rm -it -p 8080:8080 ${IMAGE_NAME}:${IMAGE_VERSION} sh

shroot:
	docker run --rm -it -p 8080:8080 --user root ${IMAGE_NAME}:${IMAGE_VERSION} sh
