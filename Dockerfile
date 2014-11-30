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
COPY modules /root/ngx_modules
COPY ngx_source /root/ngx_source
RUN cd /root/ngx_source \
    && ./configure \
      --with-cc-opt="$(dpkg-buildflags --get CFLAGS) $(dpkg-buildflags --get CPPFLAGS)" \
      --with-ld-opt="$(dpkg-buildflags --get LDFLAGS)" \
      --prefix=/usr/local \
      --sbin-path=/usr/local/sbin \
      --conf-path=/etc/nginx/nginx.conf \
      --http-log-path=/var/log/nginx/access.log \
      --error-log-path=/var/log/nginx/error.log \
      --lock-path=/var/lock/nginx.lock \
      --pid-path=/run/nginx.pid \
      --http-client-body-temp-path=/var/lib/nginx/body \
      --http-fastcgi-temp-path=/var/lib/nginx/fastcgi \
      --http-proxy-temp-path=/var/lib/nginx/proxy \
      --http-scgi-temp-path=/var/lib/nginx/scgi \
      --http-uwsgi-temp-path=/var/lib/nginx/uwsgi \
      --with-debug \
      --with-pcre-jit \
      --with-ipv6 \
      --with-http_ssl_module \
      --with-http_stub_status_module \
      --with-http_realip_module \
      --with-http_auth_request_module \
      --with-http_addition_module \
      --with-http_geoip_module \
      --with-http_gzip_static_module \
      --with-http_image_filter_module \
      --with-http_spdy_module \
      --with-http_sub_module \
      --with-http_xslt_module \
      --add-module=/root/ngx_modules/ngx_devel_kit \
      --add-module=/root/ngx_modules/set-misc-nginx-module \
      --add-module=/root/ngx_modules/lua-nginx-module \
    && make -j2 \
    && make install \
    && rm -rf /root/ngx_modules /root/ngx_source \
    && mkdir --parents /var/lib/nginx

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

EXPOSE 80 443
CMD ["run-nginx.sh"]
