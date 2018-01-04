#!/bin/bash
:<<tinywan
[1] Author：Tinywan
    Github: https://github.com/Tinywan
[2] function: 主要安装脚本
tinywan
# 服务器组字符串
SERVER_VAR=$1
SERVER=$2
SIGN=$3
API_URL="https://www.tinywan.com/frontend/websocket_client/autoInstallConf"

# [01]
function log() {
    if [ $1 == "info" ]; then
        echo -e "\033[32;40m$2\033[0m"
    elif [ $1 == "error" ]; then
        echo -e "\033[31;40m$2\033[0m"
    elif [ $1 == "debug" ]; then
        echo -e "\033[34;40m$2\033[0m"
    fi
}

# [01-01]
function init_data() {
  log debug "[`date '+%Y-%m-%d %H:%M:%S'`] All-Param : SERVER_VAR=${SERVER_VAR} SERVER=${SERVER} SIGN=${SIGN}"
  # init param
  INSTALL_PACKAGE_PATH=/root
  OPENRESTY_VERSION=$(curl -s "${API_URL}?sign=${SIGN}" | jq '.data.version_config.openresty_version' | sed 's/\"//g')
  RTMP_VERSION=$(curl -s "${API_URL}?sign=${SIGN}" | jq '.data.version_config.rtmp_version' | sed 's/\"//g')
  PKG_NAMES_JSON=$(curl -s "${API_URL}?sign=${SIGN}" | jq '.data.package_config.common' | sed 's/\"//g')
  PHP_PKG_NAMES_JSON=$(curl -s "${API_URL}?sign=${SIGN}" | jq '.data.package_config.php5' | sed 's/\"//g')
  
  # string-to-array
  OLD_IFS="$IFS"
  IFS=","
  SERVERS=($SERVER_VAR)
  PKG_NAMES=($PKG_NAMES_JSON)
  PHP_PKG_NAMES=($PHP_PKG_NAMES_JSON)
  IFS="$OLD_IFS"

  # 单独获取响应的IP地址，剩余的为直播节点IP地址
  PUSH_SERVER=${SERVERS[0]}
  PROXY_SERVER=${SERVERS[${#SERVERS[*]}-1]}
 
  log debug "[`date '+%Y-%m-%d %H:%M:%S'`] URL-JSON : OPENRESTY_VERSION=${OPENRESTY_VERSION} RTMP_VERSION=${RTMP_VERSION} INSTALL_PACKAGE_PATH=${INSTALL_PACKAGE_PATH}"
  log debug "[`date '+%Y-%m-%d %H:%M:%S'`] PKG-NAMES : PKG_NAMES_JSON=${PKG_NAMES_JSON} PHP_PKG_NAMES_JSON=${PHP_PKG_NAMES_JSON}"
}

#for i in ${PKG_NAMES[@]}
#do
#  log error "PKG_NAMES == $i "
#done
#exit 1

# [02]
function check_operating_system() {
   log debug "[`date '+%Y-%m-%d %H:%M:%S'`] IP:${SERVER} 服务器系统版本检查" 
   sleep 3
   if [ $(cat /etc/issue |awk '{print $1}') != "Ubuntu" ]; then
	log error "Only support ubuntu operating system!"
    	exit 1
    fi
}

# [04]
function check_account(){
    log debug "[`date '+%Y-%m-%d %H:%M:%S'`] IP:${SERVER} 登陆账号root检查 " 
    sleep 3
    if [ $USER != "root" ]; then
    	log error "Please use root account operation!"
        exit 1
    fi
}

# [04-1]
function check_www_exist(){
    N_USER=www
    N_GROUP=www
    #create group if not exists
    egrep "^$N_GROUP" /etc/group >& /dev/null
    if [ $? -ne 0 ]
    then
        log error "${N_GROUP} not exit"
        groupadd $N_GROUP
    fi

    #create user if not exists
    egrep "^$N_USER" /etc/passwd >& /dev/null
    if [ $? -ne 0 ]
    then
        log error "${N_USER} not exit"
        useradd -m $N_USER -g $N_GROUP
    fi
    mkdir -p /home/www/bin/logs
}

# [04-2]
function check_ip() {
    local IP=$1
    local VALID_CHECK=$(echo $IP|awk -F. '$1<=255&&$2<=255&&$3<=255&&$4<=255{print "yes"}')
    if echo $IP|grep -E "^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$" >/dev/null; then
        if [ ${VALID_CHECK:-no} == "yes" ]; then
            return 0
        else
            echo "IP $IP not available!"
            return 1
        fi
    else
        echo "IP format error!"
        return 1
    fi
}

# [05-01]
function check_pkg() {
    if ! $(dpkg -l $PKG_NAME >/dev/null 2>&1); then
        echo no
    else
        echo yes
    fi
}

# [05-02]
function update_sources_list(){
    log debug "[`date '+%Y-%m-%d %H:%M:%S'`] IP:${SERVER}  update sources.list ..."
    cp -r /etc/apt/sources.list /etc/apt/sources.list.bak
    cp -r $INSTALL_PACKAGE_PATH/auto-install-package/sources.list /etc/apt/sources.list 
    apt-get update 
    # 强制安装 jq
    apt-get install jq --force-yes -y
}

# [06]
function install_pkg() {
    local PKG_NAME=$1
    log debug "[`date '+%Y-%m-%d %H:%M:%S'`] IP:${SERVER}  [$PKG_NAME] package start install..."
    # 11
    apt-get install $PKG_NAME --force-yes -y
    #if [ $(check_pkg $PKG_NAME) == "no" ]; then
    #    apt-get install $PKG_NAME -y
    #    if [ $(check_pkg $PKG_NAME) == "no" ]; then
    #        log error "The $PKG_NAME installation failure! Try to install again."
    #        apt-get autoremove && apt-get update
    #        apt-get install $PKG_NAME --force-yes -y
    #        [ $(check_pkg $PKG_NAME) == "no" ] && log error "The $PKG_NAME installation failure!" && exit 1
    #    fi
    #fi
}

# [07]
function install_preparate_environment(){
    log debug "[`date '+%Y-%m-%d %H:%M:%S'`] IP:${SERVER} apt-get update starting ..."
    apt-get update
    log debug "[`date '+%Y-%m-%d %H:%M:%S'`] IP:${SERVER} apt-get update end ..."
    for pkg in "${PKG_NAMES[@]}"
    do
    	install_pkg $pkg
    done
}

# [08]
function build_openresty(){
    log debug "[`date '+%Y-%m-%d %H:%M:%S'`] IP:${SERVER} openresty start download ..."
    cd $INSTALL_PACKAGE_PATH/auto-install-package
    $(wget "https://openresty.org/download/openresty-$OPENRESTY_VERSION.tar.gz" && tar zxvf openresty-$OPENRESTY_VERSION.tar.gz && rm openresty-$OPENRESTY_VERSION.tar.gz)
    $(wget "https://github.com/arut/nginx-rtmp-module/archive/v$RTMP_VERSION.tar.gz" && tar zxvf v$RTMP_VERSION.tar.gz && rm v$RTMP_VERSION.tar.gz)
    log debug "[`date '+%Y-%m-%d %H:%M:%S'`] IP:${SERVER} openresty finished download"
    log debug "[`date '+%Y-%m-%d %H:%M:%S'`] IP:${SERVER} openresty start build ..."
    export PATH=$PATH:/sbin
    cd openresty-$OPENRESTY_VERSION
    ./configure --prefix=/usr/local/openresty --with-luajit --without-http_redis2_module --with-http_iconv_module  --add-dynamic-module=$INSTALL_PACKAGE_PATH/auto-install-package/nginx-rtmp-module-$RTMP_VERSION
    make && make install
    log debug "[`date '+%Y-%m-%d %H:%M:%S'`] IP:${SERVER} openresty finished build"
}

# [09] install ffmpeg
function install_ffmpeg(){
    log debug "[`date '+%Y-%m-%d %H:%M:%S'`] IP:${SERVER} FFMPEG Starting install ..."
    apt-get install software-properties-common --force-yes -y
    add-apt-repository ppa:kirillshkrogalev/ffmpeg-next
    apt-get update
    apt-get install ffmpeg --force-yes -y
}

# [10] install Redis
function install_redis(){
    install_pkg redis-server
}

# [11] install osscmd
function install_osscmd(){
    # osscmd config
    OSSCMD_HOST=$(curl -s "${API_URL}?sign=${SIGN}" | jq '.data.oss_config.host' | sed 's/\"//g')
    OSSCMD_ACCESS_KEY=$(curl -s "${API_URL}?sign=${SIGN}" | jq '.data.oss_config.access_key' | sed 's/\"//g')
    OSSCMD_KEY_SECRET=$(curl -s "${API_URL}?sign=${SIGN}" | jq '.data.oss_config.key_secret' | sed 's/\"//g')
    log debug "[`date '+%Y-%m-%d %H:%M:%S'`] IP:${SERVER} OSS_Python_API download starting ..."
    cd $INSTALL_PACKAGE_PATH/auto-install-package && mkdir OSSCMD
    $(wget "https://docs-aliyun.cn-hangzhou.oss.aliyun-inc.com/internal/oss/0.0.4/assets/sdk/OSS_Python_API_20160419.zip" && unzip OSS_Python_API_20160419.zip -d OSSCMD && rm OSS_Python_API_20160419.zip)
    log debug " [`date '+%Y-%m-%d %H:%M:%S'`] IP:${SERVER} OSS_Python_API download end"
    log debug " [`date '+%Y-%m-%d %H:%M:%S'`] IP:${SERVER} OSS_Python_API install start ..."
    $(cd OSSCMD && python setup.py install && ln -s `pwd`/osscmd /usr/local/bin/osscmd)
    #$(cd OSSCMD && python setup.py install)
    # config oss Notice:在这里不可以使用: $()
    osscmd config --host="${OSSCMD_HOST}" --id="${OSSCMD_ACCESS_KEY}" --key="${OSSCMD_KEY_SECRET}"
    log debug "[`date '+%Y-%m-%d %H:%M:%S'`] IP:${SERVER} OSS_Python_API install end "
}

# [12] Nginx Auto Server
function nginx_auto_start_service(){
    cp $INSTALL_PACKAGE_PATH/auto-install-package/nginx /etc/init.d/nginx
    chmod +x /etc/init.d/nginx && update-rc.d nginx defaults && service nginx start
}

# [13] PHP Install && Restart
# extension：Redis、Phalcon、MySQL、Cli
function install_php5_extension(){
    for pkg in "${PHP_PKG_NAMES[@]}"
    do
        install_pkg $pkg
    done
    curl -s "https://packagecloud.io/install/repositories/phalcon/stable/script.deb.sh" | sudo bash && apt-get install php5-phalcon --force-yes -y
    service php5-fpm restart
}

# [14] 推流、录像服务器
function install_config_push_server(){
    # 1、安装redis
    install_redis
    # 2、配置
    cp -r $INSTALL_PACKAGE_PATH/auto-install-package/conf/nginx-push.conf /usr/local/openresty/nginx/conf/nginx.conf
    cp -r $INSTALL_PACKAGE_PATH/auto-install-package/stat.xsl /usr/local/openresty/nginx/html
    # 3、录制文件存储和脚本移动
    mkdir -p /home/www/record-flv && chmod 777 /home/www/record-flv
    cp -r $INSTALL_PACKAGE_PATH/auto-install-package/push_to_node.sh /home/www/bin/
    cp -r $INSTALL_PACKAGE_PATH/auto-install-package/rtmp_record.sh /home/www/bin/
}

# [15] 节点服务器
function install_config_live_node_server(){
    # 1、安装redis
    install_redis
    # 2、配置
    cp -r $INSTALL_PACKAGE_PATH/auto-install-package/conf/nginx-live-node.conf /usr/local/openresty/nginx/conf/nginx.conf
    cp -r $INSTALL_PACKAGE_PATH/auto-install-package/stat.xsl /usr/local/openresty/nginx/html
    # 3、脚本
    cp -r $INSTALL_PACKAGE_PATH/auto-install-package/stream_live_node_inner_ip.sh /home/www/bin/
    # 4、启动服务
}

# [16] 直播节点代理服务器
function install_config_live_proxy_server(){
    # 1、安装redis
    install_redis
    # 2、配置
    cp -r $INSTALL_PACKAGE_PATH/auto-install-package/conf/nginx-live-node-proxy.conf /usr/local/openresty/nginx/conf/nginx.conf
    # 3、脚本
    mkdir -p /usr/local/openresty/nginx/conf/lua
    cp -r $INSTALL_PACKAGE_PATH/auto-install-package/lua/proxy_pass_livenode.lua /usr/local/openresty/nginx/conf/lua/
    cp -r $INSTALL_PACKAGE_PATH/auto-install-package/lua/hls_url_access.lua /usr/local/openresty/nginx/conf/lua/
    # 4、启动服务
}

function main(){
    # 这里需要传递一个数组作为判断的依据，例如：和传递的第一个参数做对比后，然后安装自己的配置以及复制配置文件既可以
    check_operating_system
    check_account
    # 必须要新建的目录
    check_www_exist
    log debug "[`date '+%Y-%m-%d %H:%M:%S'`] IP:${SERVER} Main Function Running Starting ..."
    sleep 3
    # [main-04]
    update_sources_list
    # [main-05]
    init_data
    # [main-06]
    install_preparate_environment
    # [main-07]
    build_openresty
    # condition install:
    case $SERVER in
        #------------------------------------------------------------------------------------
        # [01] 推流分发录像服务器
        #------------------------------------------------------------------------------------
        # [1] 推流
        # [2] 流分发shell脚本
        # [3] osscmd 安装
        # [4] 录像shell脚本
        # [5] push_nginx.conf
        ######################################################################################
        "${PUSH_SERVER}")
        log debug "[`date '+%Y-%m-%d %H:%M:%S'`] IP:${SERVER} install_config_push_server Starting Install & Config..."
        sleep 3
        install_config_push_server
        nginx_auto_start_service
    	install_ffmpeg
        install_redis
        install_osscmd
        #install_php5_extension
        ;;
        #------------------------------------------------------------------------------------
        # [02]反向代理Proxy
        #------------------------------------------------------------------------------------
        # [1] proxy_pass_livenode.lua 自动查找脚本
        # [2] hls_address_auth.lua 权限验证脚本
        # [3] proxy-nginx.conf 权限验证脚本
        ######################################################################################
        "${PROXY_SERVER}")
        log debug "[`date '+%Y-%m-%d %H:%M:%S'`] IP:${SERVER} install_config_live_proxy_server Startting Install..."
        sleep 3
	install_config_live_proxy_server
        nginx_auto_start_service
        ;;
	#------------------------------------------------------------------------------------
        # [03] 默认安装节点服务器
        #------------------------------------------------------------------------------------
        # [1]live-node-nginx.conf
        ######################################################################################
        *)
	log debug "[`date '+%Y-%m-%d %H:%M:%S'`] IP:${SERVER}  install_config_live_node_server Startting Install..."
	sleep 3
	install_config_live_node_server
	nginx_auto_start_service
        ;;
    esac
}

main

log debug "[`date '+%Y-%m-%d %H:%M:%S'`] IP:${SERVER} --------------------安装完毕 -------------------"
