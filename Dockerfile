FROM debian:buster-slim

ARG GH_RUNNER_VERSION
ARG DOCKER_COMPOSE_VERSION="1.24.1"

ENV RUNNER_NAME=""
ENV RUNNER_WORK_DIRECTORY="_work"
ENV RUNNER_TOKEN=""
ENV RUNNER_REPOSITORY_URL=""
ENV RUNNER_ALLOW_RUNASROOT=true
ENV GITHUB_ACCESS_TOKEN=""

# Labels.
LABEL maintainer="realanmup@gmail.com" \
    org.label-schema.schema-version="1.0" \
    org.label-schema.build-date=$BUILD_DATE \
    org.label-schema.vcs-ref=$VCS_REF \
    org.label-schema.name="realanmup/github-runner" \
    org.label-schema.description="Dockerized GitHub Actions runner." \
    org.label-schema.url="https://github.com/realanmup/github-runner" \
    org.label-schema.vcs-url="https://github.com/realanmup/github-runner" \
    org.label-schema.vendor="Saurav Giri" \
    org.label-schema.docker.cmd="docker run -it realanmup/github-runner:latest"

RUN DEBIAN_FRONTEND=noninteractive apt-get update && \
    apt-get install -y \
        curl \
        apt-transport-https \
        ca-certificates \
        curl \
        software-properties-common \
        git \
        sudo \
        supervisor \
        jq \
        iputils-ping \
        build-essential

COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
RUN chmod 644 /etc/supervisor/conf.d/supervisord.conf

# Install Docker CLI
RUN curl -fsSL https://get.docker.com -o get-docker.sh && sh get-docker.sh

# Install Docker-Compose
RUN curl -L "https://github.com/docker/compose/releases/download/1.24.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose && \
    chmod +x /usr/local/bin/docker-compose

RUN apt install nodejs npm -yqq


RUN npm i -g yarn n

RUN n i 12

RUN apt install python3 python3-pip -yqq

RUN pip3 install --upgrade awscli

RUN curl https://releases.hashicorp.com/terraform/0.12.19/terraform_0.12.26_linux_amd64.zip > terraform.zip
RUN unzip terraform.zip -d /usr/local/bin


RUN rm -rf /var/lib/apt/lists/* && \
    apt-get clean

RUN mkdir -p /home/runner

WORKDIR /home/runner

RUN GH_RUNNER_VERSION=${GH_RUNNER_VERSION:-$(curl --silent "https://api.github.com/repos/actions/runner/releases/latest" | grep tag_name | sed -E 's/.*"v([^"]+)".*/\1/')} \
    && curl -L -O https://github.com/actions/runner/releases/download/v${GH_RUNNER_VERSION}/actions-runner-linux-x64-${GH_RUNNER_VERSION}.tar.gz \
    && tar -zxf actions-runner-linux-x64-${GH_RUNNER_VERSION}.tar.gz \
    && rm -f actions-runner-linux-x64-${GH_RUNNER_VERSION}.tar.gz \
    && ./bin/installdependencies.sh \
    && chown -R root: /home/runner

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
