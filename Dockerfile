FROM debian:latest
MAINTAINER Wouter Admiraal <wad@wadmiraal.net>
ENV DEBIAN_FRONTEND noninteractive
RUN rm /bin/sh && ln -s /bin/bash /bin/sh

# Install packages.
RUN apt-get update
RUN apt-get install -y \
	vim \
	git \
	apache2 \
	php-apc \
	php5-fpm \
	php5-cli \
	php5-mysql \
	php5-gd \
	php5-curl \
	libapache2-mod-php5 \
	curl \
	mysql-server \
	mysql-client \
	openssh-server \
	supervisor
RUN apt-get clean

# Install Composer.
RUN curl -sS https://getcomposer.org/installer | php
RUN mv composer.phar /usr/local/bin/composer

# Install Drush 6.
RUN composer global require drush/drush:6.*
RUN composer global update
# Unfortunately, adding the composer vendor dir to the PATH doesn't seem to work. So:
RUN ln -s /root/.composer/vendor/bin/drush /usr/local/bin/drush

# Setup Apache.
RUN sed -i 's/AllowOverride None/AllowOverride All/' /etc/apache2/sites-available/default
RUN a2enmod rewrite

# Setup MySQL, bind on all addresses.
RUN sed -i -e"s/^bind-address\s*=\s*127.0.0.1/#bind-address = 127.0.0.1/" /etc/mysql/my.cnf

# Setup SSH.
RUN echo 'root:root' | chpasswd
RUN sed -i 's/PermitRootLogin without-password/PermitRootLogin yes/' /etc/ssh/sshd_config
RUN mkdir /var/run/sshd && chmod 0755 /var/run/sshd
RUN mkdir -p /root/.ssh/ && touch /root/.ssh/authorized_keys
RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd

# Setup Supervisor.
RUN echo -e '[program:apache2]\ncommand=/bin/bash -c "source /etc/apache2/envvars && exec /usr/sbin/apache2 -DFOREGROUND"\nautorestart=true\n\n' >> /etc/supervisor/supervisord.conf
RUN echo -e '[program:mysql]\ncommand=/usr/bin/pidproxy /var/run/mysqld/mysqld.pid /usr/sbin/mysqld\nautorestart=true\n\n' >> /etc/supervisor/supervisord.conf
RUN echo -e '[program:sshd]\ncommand=/usr/sbin/sshd -D\n\n' >> /etc/supervisor/supervisord.conf

# Install Drupal.
RUN rm -rf /var/www
RUN cd /var && \
	drush dl drupal && \
	mv /var/drupal* /var/www
RUN mkdir -p /var/www/sites/default/files && \
	chmod a+w /var/www/sites/default -R && \
	mkdir /var/www/sites/all/modules/contrib -p && \
	mkdir /var/www/sites/all/modules/custom && \
	mkdir /var/www/sites/all/themes/contrib -p && \
	mkdir /var/www/sites/all/themes/custom && \
	chown -R www-data:www-data /var/www/
RUN /etc/init.d/mysql start && \
	cd /var/www && \
	drush si -y minimal --db-url=mysql://root:@localhost/drupal --account-pass=admin && \
	drush dl admin_menu && \
	drush en -y admin_menu

EXPOSE 80 3306 22
CMD exec supervisord -n
