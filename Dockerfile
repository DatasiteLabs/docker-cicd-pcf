FROM golang:1.11-alpine3.8
RUN apk update
RUN apk upgrade

RUN apk --no-cache add jq bash git curl tar gzip

# Add jfrog cli
RUN curl -fL https://getcli.jfrog.io | sh \
    && mv ./jfrog /usr/local/bin/jfrog \
    && chmod 777 /usr/local/bin/jfrog

ADD https://cli.run.pivotal.io/stable?release=linux64-binary /tmp/cf-cli.tgz
RUN mkdir -p /usr/local/bin && tar -xzf /tmp/cf-cli.tgz -C /usr/local/bin && cf --version && rm -f /tmp/cf-cli.tgz
RUN git clone https://github.com/cloudfoundry-incubator/app-autoscaler-cli-plugin.git && cd app-autoscaler-cli-plugin && source .envrc && git submodule update --init --recursive && ./scripts/build && cf install-plugin out/ascli -f

RUN addgroup -g 1000 -S pcf && \
	adduser -u 1000 -S pcf -G pcf

COPY cf-cli.sh /usr/local/bin
COPY rolling-deploy.sh /usr/local/bin
VOLUME /home/pcf/tools
WORKDIR /home/pcf
# CMD ["bash"]
CMD ["cf", "--version"]