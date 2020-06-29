FROM ubuntu:18.04

ENV ANSIBLE_VERSION 2.9.6

ENV LANG=en_US.UTF-8
ENV SHELL=/bin/bash

# Install coder
RUN apt-get update \
 && apt-get install -y \
    curl \
    dumb-init \
    htop \
    locales \
    man \
    nano \
    git \
    procps \
    ssh \
    sudo \
    vim \
    unzip \
    byobu \
# Terraform requirements
    update \
    python3-pip \
# Ansible requirement
    sshpass \
  && rm -rf /var/lib/apt/lists/*

# https://wiki.debian.org/Locale#Manually
RUN sed -i "s/# en_US.UTF-8/en_US.UTF-8/" /etc/locale.gen \
  && locale-gen

RUN chsh -s /bin/bash

RUN adduser --gecos '' --disabled-password coder && \
    echo "coder ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/nopasswd

RUN curl -SsL https://github.com/boxboat/fixuid/releases/download/v0.4/fixuid-0.4-linux-amd64.tar.gz | tar -C /usr/local/bin -xzf - && \
    chown root:root /usr/local/bin/fixuid && \
    chmod 4755 /usr/local/bin/fixuid && \
    mkdir -p /etc/fixuid && \
    printf "user: coder\ngroup: coder\n" > /etc/fixuid/config.yml

#COPY release/code-server*.tar.gz /tmp/
RUN cd /tmp && wget https://github.com/cdr/code-server/releases/download/v3.4.1/code-server-3.4.1-linux-amd64.tar.gz

RUN cd /tmp && \
    tar -xzf code-server*.tar.gz && \
    rm code-server*.tar.gz && \
    mv code-server* /usr/local/lib/code-server && \
    ln -s /usr/local/lib/code-server/code-server /usr/local/bin/code-server

# Install Terraform
RUN wget https://releases.hashicorp.com/terraform/0.12.23/terraform_0.12.23_linux_amd64.zip && \ 
    unzip terraform_0.12.23_linux_amd64.zip && \
    mv terraform /usr/local/bin/ && \ 
    terraform --version && \ 
    pip3 install --upgrade pip && \ 
    python3 -V && \ 
    pip --version && \ 
    pip install docker && \ 
    pip install azure-cli && \ 

# Install Ansible
RUN set -x && \
    \
    echo "==> Adding Python runtime..."  && \
    pip install --upgrade pip && \
    pip install python-keyczar docker-py && \
    \
    echo "==> Installing Ansible..."  && \
    pip install ansible==${ANSIBLE_VERSION} && \
    \
    pip install pywinrm

# Install Jupyter
RUN pip install notebook

EXPOSE 8080 8081
USER coder
WORKDIR /home/coder
ENTRYPOINT ["dumb-init", "fixuid", "-q", "/usr/local/bin/code-server", "--host", "0.0.0.0", "."]
