FROM hexpm/elixir:1.18.4-erlang-27.3-alpine-3.18.9

# Install build tools
RUN \
    mkdir -p /opt/app && \
    chmod -R 777 /opt/app && \
    apk update && \
    apk --no-cache --update add \
      bash \
      build-base \
      ca-certificates \
      curl \
      git \
      inotify-tools \
      nodejs \
      npm \
      postgresql-client \
      python3 \
      vim \
      wget && \
    update-ca-certificates --fresh && \
    rm /etc/ssl/cert.pem && ln -s /etc/ssl/certs/ca-certificates.crt /etc/ssl/cert.pem && \
    ln -nfs /usr/bin/python3 /usr/bin/python && \
    rm -rf /var/cache/apk/*

# Add local node module binaries to PATH
ENV PATH=./node_modules/.bin:$PATH

# Ensure latest versions of Hex/Rebar are installed on build
ONBUILD RUN mix do local.hex --force, local.rebar --force

WORKDIR /opt/app

CMD ["/bin/sh"]
