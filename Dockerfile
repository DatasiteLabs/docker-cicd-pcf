FROM alpine:3.16
ARG PCF_CLI_VERSION

RUN apk update && apk add \ 
	bash \ 
	jq \ 
	curl \ 
	git \
	tar \
	procps \
	gzip

# Add jfrog cli
RUN curl -fL https://getcli.jfrog.io | sh \
    && mv ./jfrog /usr/local/bin/jfrog \
    && chmod 777 /usr/local/bin/jfrog

RUN wget -qO- "https://packages.cloudfoundry.org/stable?release=linux64-binary&version=${PCF_CLI_VERSION}&source=github-rel" | tar -zx && \
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
