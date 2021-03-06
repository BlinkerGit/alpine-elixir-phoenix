FROM hexpm/elixir:1.12.1-erlang-24.0.2-alpine-3.13.3

# Install build tools
RUN \
    mkdir -p /opt/app && \
    chmod -R 777 /opt/app && \
    apk update && \
    apk --no-cache --update add \
      bash \
      ca-certificates \
      curl \
      g++ \
      git \
      inotify-tools \
      make \
      nodejs \
      nodejs-npm \
      python2 \
      vim \
      wget && \
    npm install npm -g --no-progress && \
    update-ca-certificates --fresh && \
    rm /etc/ssl/cert.pem && ln -s /etc/ssl/certs/ca-certificates.crt /etc/ssl/cert.pem && \
    ln -nfs /usr/bin/python2 /usr/bin/python && \
    rm -rf /var/cache/apk/*

# Add local node module binaries to PATH
ENV PATH=./node_modules/.bin:$PATH

# Ensure latest versions of Hex/Rebar are installed on build
ONBUILD RUN mix do local.hex --force, local.rebar --force

WORKDIR /opt/app

CMD ["/bin/sh"]
