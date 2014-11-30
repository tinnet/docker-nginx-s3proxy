#!/usr/bin/env bash

set -e

cd $HOME

# download sources
mkdir --parents ./nginx-src
curl -L http://nginx.org/download/nginx-1.7.7.tar.gz | tar xz -C ./nginx-src --strip-components=1

mkdir --parents ./ngx_devel_kit
curl -L https://github.com/simpl/ngx_devel_kit/archive/v0.2.19.tar.gz | tar xz -C ./ngx_devel_kit --strip-components=1

mkdir --parents ./set-misc-nginx-module
curl -L https://github.com/openresty/set-misc-nginx-module/archive/v0.27.tar.gz | tar xz -C ./set-misc-nginx-module --strip-components=1

mkdir --parents ./lua-nginx-module
curl -L https://github.com/openresty/lua-nginx-module/archive/v0.9.13.tar.gz | tar xz -C ./lua-nginx-module --strip-components=1

# build & install nginx (configure flags are nginx-full + our modules)
cd ./nginx-src
./configure \
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
      --add-module=$HOME/ngx_devel_kit \
      --add-module=$HOME/set-misc-nginx-module \
      --add-module=$HOME/lua-nginx-module
make -j2
make install
mkdir --parents /var/lib/nginx

# cleanup
cd $HOME
rm -rf ./nginx-src
rm -rf ./ngx_devel_kit
rm -rf ./set-misc-nginx-module
rm -rf ./lua-nginx-module
