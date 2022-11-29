FROM docker.io/bitnami/minideb:bullseye

ARG TARGETARCH

LABEL org.opencontainers.image.authors="https://bitnami.com/contact; flavoured by https://sidlibrary.org" \
      org.opencontainers.image.description="Application packaged by Bitnami; flavoured by Sidney Jeong" \
      org.opencontainers.image.ref.name="ghost-5.24.2-bullseye-r0" \
      org.opencontainers.image.source="https://github.com/sid0831/ghost-container" \
      org.opencontainers.image.title="ghost" \
      org.opencontainers.image.vendor="VMware, Inc.; Sidney Jeong" \
      org.opencontainers.image.version="5.24.2"

ENV HOME="/" \
    OS_ARCH="${TARGETARCH:-amd64}" \
    OS_FLAVOUR="debian-11" \
    OS_NAME="linux"

COPY prebuildfs /
SHELL [ "/bin/bash", "-o", "pipefail", "-c" ]
# Install required system packages and dependencies
RUN install_packages apt-utils ca-certificates acl gnupg curl
RUN curl -fsSL https://deb.nodesource.com/setup_16.x | /bin/bash - && \
    install_packages jq libaudit1 libbz2-1.0 libcap-ng0 libcom-err2 libcrypt1 libffi7 libgcc-s1 libgssapi-krb5-2 libk5crypto3 libkeyutils1 libkrb5-3 libkrb5support0 liblzma5 libncurses6 libncursesw6 libnsl2 libpam0g libreadline8 libsqlite3-0 libstdc++6 libtinfo6 libtirpc3 libxml2 procps zlib1g python3 nodejs yarn gosu libssl1.1 libicu67 libaio1 libncurses5
RUN mkdir -p /tmp/bitnami/pkg/cache/ && cd /tmp/bitnami/pkg/cache/ && \
   COMPONENTS=( \
       "$(curl -SsfL https://raw.githubusercontent.com/bitnami/containers/main/bitnami/ghost/5/debian-11/Dockerfile | grep 'ghost-.*-linux-.*-debian-11' - | tr -d '"\\ ' | sed -e 's/${OS_ARCH}/amd64/')" \
       "$(curl -SsfL https://raw.githubusercontent.com/bitnami/containers/main/bitnami/ghost/5/debian-11/Dockerfile | grep 'mysql-client-.*-linux-.*-debian-11' - | tr -d '"\\ ' | sed -e 's/${OS_ARCH}/amd64/')" \
    ) && \
    for COMPONENT in "${COMPONENTS[@]}"; do \
      if [ ! -f "${COMPONENT}.tar.gz" ]; then \
        curl -SsLf "https://downloads.bitnami.com/files/stacksmith/${COMPONENT}.tar.gz" -O ; \
        curl -SsLf "https://downloads.bitnami.com/files/stacksmith/${COMPONENT}.tar.gz.sha256" -O ; \
      fi && \
      sha256sum -c "${COMPONENT}.tar.gz.sha256" && \
      tar -zxf "${COMPONENT}.tar.gz" -C /opt/bitnami --strip-components=2 --no-same-owner --wildcards '*/files' && \
      rm -rf "${COMPONENT}".tar.gz{,.sha256} ; \
    done
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get --autoremove full-upgrade -y && \
    apt-get clean && rm -rf /var/lib/apt/lists /var/cache/apt/archives
RUN chmod g+rwX /opt/bitnami

COPY rootfs /
RUN /opt/bitnami/scripts/ghost/postunpack.sh
RUN /opt/bitnami/scripts/mysql-client/postunpack.sh
ENV APP_VERSION="5.24.2" \
    BITNAMI_APP_NAME="ghost" \
    PATH="/opt/bitnami/python/bin:/opt/bitnami/node/bin:/opt/bitnami/mysql/bin:/opt/bitnami/common/bin:/opt/bitnami/ghost/bin:$PATH"
EXPOSE 2368 3000

WORKDIR /opt/bitnami/ghost
USER 1001
ENTRYPOINT [ "/opt/bitnami/scripts/ghost/entrypoint.sh" ]
CMD [ "/opt/bitnami/scripts/ghost/run.sh" ]
