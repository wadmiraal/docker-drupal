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
	curl \
	mysql-server \
	mysql-client \
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

# Setup Supervisor.
RUN echo -e '[supervisord]\nnodaemon=true\n\n' >> /etc/supervisor/supervisord.conf
RUN echo -e '[program:apache2]\ncommand=/bin/bash -c "source /etc/apache2/envvars && exec /usr/sbin/apache2 -DFOREGROUND"\n\n' >> /etc/supervisor/supervisord.conf

# Install Drupal.
RUN rm -rf /var/www
RUN cd /var && drush dl drupal && mv /var/drupal* /var/www
RUN mkdir -p /var/www/sites/default/files && chmod a+w /var/www/sites/default -R && chown -R www-data:www-data /var/www/
RUN /etc/init.d/mysql start && cd /var/www && drush si -y --db-url=mysql://root:@localhost/drupal --account-pass=admin

EXPOSE 80 22 6081

