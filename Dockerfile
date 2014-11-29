FROM debian:wheezy

# apt stuff...
RUN export DEBIAN_FRONTEND=noninteractive \
    && echo 'force-unsafe-io' > /etc/dpkg/dpkg.cfg.d/02apt-speedup \
    && echo "deb http://http.debian.net/debian/ wheezy-backports main" > /etc/apt/sources.list.d/backports.list \
    && echo "deb-src http://http.debian.net/debian/ wheezy main" > /etc/apt/sources.list.d/src.list \
    && echo "deb-src http://http.debian.net/debian/ wheezy-backports main" >> /etc/apt/sources.list.d/src.list \
    && apt-get update \
    && apt-get -y install --no-install-recommends build-essential curl ca-certificates \
    && apt-get -y -t wheezy-backports build-dep nginx \
    && apt-get -q -y clean \
    && rm -rf /var/cache/apt/archives/* /var/lib/apt/lists/* \
    && rm -rf /usr/share/man/?? /usr/share/man/??_*

# download & compile ngix...
COPY install-nginx.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/install-nginx.sh
RUN install-nginx.sh

## html5 boilerplate config - courtesy of https://github.com/michaelcontento/docker-nginx
RUN useradd www

# we're based on the awesome work by the h5bp community
RUN curl -L https://github.com/h5bp/server-configs-nginx/archive/master.tar.gz | tar xzop -C /tmp \
    && mkdir --parents /etc/nginx \
    && cp -rf /tmp/server-configs-nginx-master/* /etc/nginx/ \
    && rm -rf /tmp/* \
    && rm -f /etc/nginx/conf.d/*

# and add / configure some additional stuff
RUN CFG="/etc/nginx/nginx.conf" \
    && sed -i -e '0,/include sites/s//include conf.d\/*.conf;\n  include sites/' $CFG \
    && sed -i -e 's/error_log .*/error_log \/dev\/stderr warn;/' $CFG \
    && sed -i -e 's/access_log .*/access_log \/dev\/stdout main;/' $CFG \
    && CFG="/etc/nginx/h5bp/location/expires.conf" \
    && sed -i -e 's/access_log .*/access_log \/dev\/stdout main;/' $CFG \
    && ln -s ../sites-available/no-default /etc/nginx/sites-enabled/

#COPY bucket.conf /etc/nginx/sites-enabled/

# poor man's CI
RUN nginx -t 2>&1

# needed to configure buckets from env vars
RUN curl -L https://github.com/kelseyhightower/confd/releases/download/v0.6.3/confd-0.6.3-linux-amd64 -o /usr/local/bin/confd \
    && chmod +x /usr/local/bin/confd \
    && mkdir --parents /etc/confd/conf.d \
    && mkdir --parents /etc/confd/templates

COPY confd_buckets.toml /etc/confd/conf.d/
COPY buckets.conf.tmpl /etc/confd/templates/
COPY run-nginx.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/run-nginx.sh

EXPOSE 80 443
CMD ["run-nginx.sh"]
