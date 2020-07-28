FROM phusion/baseimage:bionic-1.0.0

CMD ["/sbin/my_init"]

RUN DEBIAN_FRONTEND=noninteractive
RUN locale-gen en_US.UTF-8

ENV LANGUAGE=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8
ENV LC_CTYPE=en_US.UTF-8
ENV LANG=en_US.UTF-8
ENV TERM xterm

# Add a non-root user to prevent files being created with root permissions on host machine.
ARG PUID=1000
ENV PUID ${PUID}
ARG PGID=1000
ENV PGID ${PGID}

COPY keyboard /etc/default/keyboard

RUN apt-get install -y software-properties-common && \
    add-apt-repository -y ppa:ondrej/php

ARG PHP_VERSION=${PHP_VERSION}

RUN install_clean \
        php${PHP_VERSION}-cli \
        php${PHP_VERSION}-common \
        php${PHP_VERSION}-curl \
        php${PHP_VERSION}-intl \
        php${PHP_VERSION}-json \
        php${PHP_VERSION}-xml \
        php${PHP_VERSION}-mbstring \
        php${PHP_VERSION}-mysql \
        php${PHP_VERSION}-sqlite \
        php${PHP_VERSION}-sqlite3 \
        php${PHP_VERSION}-zip \
        php${PHP_VERSION}-bcmath \
        php${PHP_VERSION}-memcached \
        php${PHP_VERSION}-gd \
        php${PHP_VERSION}-dev \
        php${PHP_VERSION}-fpm \
        php${PHP_VERSION}-gmp \
        php${PHP_VERSION}-soap\
        php-imagick \
        pkg-config \
        libcurl4-openssl-dev \
        libedit-dev \
        libssl-dev \
        libxml2-dev \
        xz-utils \
        libsqlite3-dev \
        sqlite3 \
        python-pip \
        git \
        curl \
        wget \
        zip \
        unzip \
        vim \
        nano \
        safe-rm \
        xclip \
        net-tools \
        sudo \
        zsh
RUN pip install Pygments

COPY php-cli.ini /etc/php/${PHP_VERSION}/cli/php.ini
COPY php-fpm.ini /etc/php/${PHP_VERSION}/fpm/php.ini

RUN groupadd -g ${PGID} laradock
RUN useradd -u ${PUID} -g laradock -m laradock -G docker_env
RUN usermod -p "*" laradock
RUN echo laradock:laradock | chpasswd
RUN usermod -aG sudo laradock

###########################################################################
# Set Timezone
###########################################################################

ARG TZ=UTC
ENV TZ ${TZ}
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

###########################################################################
# Oh my zsh shell
###########################################################################

USER laradock

RUN wget https://github.com/robbyrussell/oh-my-zsh/raw/master/tools/install.sh -O - | zsh || true
COPY ./.zshrc /home/laradock/.zshrc
COPY ./.dir_colors /home/laradock/.dir_colors
ENV ZSH_CUSTOM=/home/laradock/.oh-my-zsh/custom
RUN git clone git://github.com/zsh-users/zsh-autosuggestions $ZSH_CUSTOM/plugins/zsh-autosuggestions

USER root

# Shared directory
RUN chown laradock:laradock /home/laradock/.zshrc
RUN mkdir -p /home/laradock/shared
RUN chown -R laradock:laradock /home/laradock/shared

###########################################################################
# User Aliases
###########################################################################

USER root

COPY ./aliases.sh /root/aliases.sh
COPY ./aliases.sh /home/laradock/aliases.sh

RUN sed -i 's/\r//' /root/aliases.sh && \
    sed -i 's/\r//' /home/laradock/aliases.sh && \
    chown laradock:laradock /home/laradock/aliases.sh && \
    echo "" >> ~/.bashrc && \
    echo "# Load Custom Aliases" >> ~/.bashrc && \
    echo "source ~/aliases.sh" >> ~/.bashrc && \
	echo "" >> ~/.bashrc

USER laradock

RUN echo "" >> ~/.bashrc && \
    echo "# Load Custom Aliases" >> ~/.bashrc && \
    echo "source ~/aliases.sh" >> ~/.bashrc && \
	echo "" >> ~/.bashrc

###########################################################################
# Symfony installer:
###########################################################################

USER laradock

RUN wget https://get.symfony.com/cli/installer -O - | bash
RUN echo "" >> ~/.bashrc && \
    echo 'export PATH="~/.symfony/bin:$PATH"' >> ~/.bashrc

#####################################
# Composer:
#####################################

USER root

RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
RUN composer self-update --stable
COPY ./composer.json /home/laradock/.composer/composer.json
RUN chown -R laradock:laradock /home/laradock/.composer

USER laradock

RUN echo "" >> ~/.bashrc && \
    echo 'export PATH="~/.composer/vendor/bin:$PATH"' >> ~/.bashrc

RUN composer global require hirak/prestissimo

###########################################################################
# Node / NVM:
###########################################################################

USER laradock

ENV NVM_DIR /home/laradock/.nvm
RUN mkdir -p /home/laradock/.nvm
RUN curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.35.0/install.sh | bash && \
        . $NVM_DIR/nvm.sh && \
        nvm install --lts && \
        nvm use --lts && \
        npm install -g bower gulp gulp-cli uglify-js uglifycss elasticdump && \
        ln -s `npm bin --global` /home/laradock/.node-bin

# Wouldn't execute when added to the RUN statement in the above block
# Source NVM when loading bash since ~/.profile isn't loaded on non-login shell
RUN echo "" >> ~/.bashrc && \
    echo 'export NVM_DIR="$HOME/.nvm"' >> ~/.bashrc && \
    echo '[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"  # This loads nvm' >> ~/.bashrc

# Add NVM binaries to root's .bashrc
USER root

RUN echo "" >> ~/.bashrc && \
    echo 'export NVM_DIR="/home/laradock/.nvm"' >> ~/.bashrc && \
    echo '[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"  # This loads nvm' >> ~/.bashrc

# Add PATH for node
ENV PATH $PATH:/home/laradock/.node-bin

###########################################################################
# Final touch:
###########################################################################

USER root

RUN echo "export PATH=$PATH" > /etc/environment
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
RUN . ~/.bashrc
