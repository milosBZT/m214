FROM ubuntu:latest as build

ARG GIT_REPO_URL
ARG PROJ_ROOT=/home/web/web-app

# These ports are expected to be used
EXPOSE 80
EXPOSE 3306

## Create user 'web'
RUN useradd -s /bin/bash -d /home/web -m -G sudo web

## Silent apt package manager and configure timezone
ENV DEBIAN_FRONTEND="noninteractive"
ENV TZ="Europe/Zurich"

## Install all needed packages
RUN apt-get update && apt-get -y upgrade
RUN apt-get -y install \
	apache2 \
	git \
	ssh \
	mariadb-server \
	php \
	libapache2-mod-php7.4

## Configure PHP for apache
RUN echo \
'<FilesMatch "\.php$">\n\
	SetHandler application/x-httpd-php\n\
 </FilesMatch>' \
>> /etc/apache2/apache2.conf

## Allow remote access to mariadb
RUN echo \
'[mysqld]\n\
 bind-address = 0.0.0.0' \
>> /etc/mysql/my.cnf

## Configure apache web server and link project dir as apache document root
## and set permissions for user web
RUN mkdir ${PROJ_ROOT}
RUN rm -r /var/www/html
RUN ln -s ${PROJ_ROOT} /var/www/html
RUN chown -R web:web /var/www/html
RUN chown -R web:web ${PROJ_ROOT}


## Run this script as entrypoint command
RUN echo \
'#!/bin/bash\n\
 service mysql start\n\
  mysql -u root -e "GRANT ALL PRIVILEGES ON *.* TO \"root\"@\"%\" IDENTIFIED BY \"admin\" WITH GRANT OPTION;"\n\
 apachectl -D FOREGROUND\n' \
> /root/script.sh

#RUN chmod +x /root/script.sh
ENTRYPOINT ["/bin/bash", "/root/script.sh"]

