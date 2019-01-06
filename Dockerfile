FROM tokaido/php72:stable
ENV DEBIAN_FRONTEND noninteractive
COPY configs/.bash_profile /etc/skel/.bash_profile
COPY configs/.bashrc /etc/skel/.bashrc
RUN apt-get update  \
    && apt-get install -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" \
        openssh-server \ 
        multitail \               
        sendmail \
    && curl -sL https://deb.nodesource.com/setup_8.x | bash - \
    && curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - \
    && echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list \
    && apt-get update \
    && apt-get install -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" \        
        nodejs \
        yarn \
        jq \        
    && /usr/bin/ssh-keygen -A  \
    && chmod 600 /etc/skel/.bash* \    
    && cp /etc/skel/.bash_profile /home/tok/.bash_profile \
    && cp /etc/skel/.bashrc /home/tok/.bashrc \
    && chown tok:web /home/tok/.bash* \
    && chmod 600 /home/tok/.bash* \        
    && mkdir /run/sshd  \
    && curl -s https://getcomposer.org/installer > composer-setup.php && php composer-setup.php && mv composer.phar /usr/local/bin/composer && rm composer-setup.php  \
    && su - tok -c "/usr/local/bin/composer global require \"hirak/prestissimo\""  \
    && su - tok -c "/usr/local/bin/composer global require \"drush/drush\""  \
    && npm install --global json-log-viewer \
    && COMPOSER_HOME=/usr/local/drush/global COMPOSER_BIN_DIR=/usr/local/drush/global/bin COMPOSER_VENDOR_DIR=/usr/local/drush/global/vendor composer require drush/drush:^8 \
    && wget -O /tmp/drush.phar https://github.com/drush-ops/drush-launcher/releases/download/0.6.0/drush.phar \
    && mv /tmp/drush.phar /usr/local/bin/drush \
    && chmod 755 /usr/local/bin/drush \
    && chmod 750 /home/tok/.composer/vendor/drush/drush/drush \    
    && curl -s http://download.redis.io/releases/redis-4.0.11.tar.gz > /tmp/redis-4.0.11.tar.gz \    
    && tar xzf /tmp/redis-4.0.11.tar.gz -C /tmp/ \
    && cd /tmp/redis-4.0.11 \
    && make && make install \
    && rm -rf /tmp/*  

COPY configs/sshd_config /etc/ssh/sshd_config
COPY configs/motd.sh /etc/motd.sh
COPY scripts/show-logs.sh /usr/local/bin/show-logs.sh
COPY scripts/tok-tips.sh /usr/local/bin/tok-tips.sh
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod 700 /usr/local/bin/entrypoint.sh \
    && chmod 755 /etc/motd.sh  \
    && rm /etc/motd \
    && chmod 770 /usr/local/bin/show-logs.sh \
    && chown tok:web /usr/local/bin/show-logs.sh \
    && ln -s /usr/local/bin/show-logs.sh /usr/local/bin/show-logs \
    && chmod 770 /usr/local/bin/tok-tips.sh \
    && ln -s /usr/local/bin/tok-tips.sh /usr/local/bin/tok-tips \
    && chown tok:web /usr/local/bin/tok-tips.sh

ENV SHELL /bin/bash
EXPOSE 22
CMD ["/usr/local/bin/entrypoint.sh"]
