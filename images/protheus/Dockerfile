FROM oraclelinux:8

# Instalação de dependências obrigatórias para o AppServer Linux
RUN dnf install -y \
    libnsl \
    glib2 \
    libpng \
    libjpeg-turbo \
    freetype \
    fontconfig \
    ncurses-compat-libs \
    bind-utils \
    iputils \
    procps-ng \
    hostname \
    glibc-langpack-en \
    && dnf clean all

# Configuração de Encoding e Timezone (Essencial para Protheus)
ENV LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8 \
    TZ=America/Sao_Paulo

# Criação de links simbólicos para timezone
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

WORKDIR /opt/totvs/appserver
