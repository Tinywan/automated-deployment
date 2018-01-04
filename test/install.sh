#/bin/bash
ERVER=$1
OPENRESTY_VERSION='1.11.2.5'
RTMP_VERSION='1.2.0'
#---config env
install_apt_get_env(){
    apt-get update
    apt-get install libreadline-dev libncurses5-dev libpcre3-dev libssl-dev perl make build-essential
    apt-get install libxml2 libxml2-dev libxslt-dev
    apt-get install libgd2-xpm libgd2-xpm-dev
}

#---openresty download
download_openresty_and_build(){
    echo '--------------------openresty download start ----------------'
    cd /home/www/auto-install-package
    wget https://openresty.org/download/openresty-$OPENRESTY_VERSION.tar.gz && tar zxvf openresty-$OPENRESTY_VERSION.tar.gz && rm openresty-$OPENRESTY_VERSION.tar.gz
    wget https://github.com/arut/nginx-rtmp-module/archive/v$RTMP_VERSION.tar.gz && tar zxvf v$RTMP_VERSION.tar.gz && rm v$RTMP_VERSION.tar.gz
    echo '--------------------openresty download end -------------------'
    echo '--------------------openresty build start-------------------'
    export PATH=$PATH:/sbin
    cd openresty-$OPENRESTY_VERSION
    ./configure --prefix=/usr/local/openresty --with-luajit --without-http_redis2_module --with-http_iconv_module  --add-dynamic-module=/home/www/auto-install-package/nginx-rtmp-module-$RTMP_VERSION
    make
    make install
    echo '--------------------openresty build end  -------------------'
}

#---Installing ffmpeg
install_ffmpeg(){
    apt-get update
    apt-get install software-properties-common
    add-apt-repository ppa:kirillshkrogalev/ffmpeg-next
    apt-get update
    apt-get install ffmpeg
}

#---install Redis
install_redis(){
    apt-get install redis-server
}

main(){
    install_apt_get_env
    download_openresty_and_build
    install_ffmpeg
}

main

