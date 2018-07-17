FROM alpine:3.7

RUN apk update && apk add \ 
	bash \ 
	jq \ 
	curl \ 
	git \
	tar \
	gzip

RUN wget -qO- "https://packages.cloudfoundry.org/stable?release=linux64-binary&source=github" | tar -zx && \
	mv cf /usr/local/bin && \
	cf --version

RUN addgroup -g 1000 -S pcf && \
	adduser -u 1000 -S pcf -G pcf

COPY cf-cli.sh /usr/local/bin
COPY rolling-deploy.sh /usr/local/bin
VOLUME /home/pcf/tools
WORKDIR /home/pcf
# CMD ["bash"]
CMD ["cf", "--version"]