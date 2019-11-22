#!/bin/bash
#author cl* 

CODE_DIR="Talent_Parent" #相当于仓库地址
MODULE_NAME="talent-api" #打包的maven模块名
PACKAGED_NAME="talent-dev" #打包生成的jar名字
GIT_PROJECT_NAME="Talent_Parent" #相当于仓库地址
GIT_BRANCH_NAME="master" # 分支
PROFILE="dev" # 环境 dev、prod等
APP_DEPLOY_PATH="/data/www/service/talent/dev" #当前脚本的地址
PORT=8088 # 启动的端口号

#如果任何语句的执行结果不是true则应该退出
set -e

#git初始化配置，配置后，无需手动输入用户名及密码即可从指定git管理代码
function gitinit(){
  echo "start gitinit..."
  cd ~/
  touch .git-credentials
  echo "http://username:password@gitee.com" > .git-credentials
  git config --global credential.helper store
  #执行此句后~/.gitconfig文件多了一项[credential] helper = store
  echo "finish gitinit..."
  
}

#pull and package gitcodeResource 
function package(){
  echo "start pull git resource code..."
  rm -rf ./$CODE_DIR
  git clone  https://gitee.com/talentcode2019/$GIT_PROJECT_NAME.git
  cd ./$CODE_DIR
  git checkout $GIT_BRANCH_NAME
  echo "git checkout succeed ..."
  echo "starting packaging app ..."
  mvn clean package -P $PROFILE -Dmaven.test.skip=true
  echo "packaging app success ..."
}

#code deploy
function deploy(){
  cd $APP_DEPLOY_PATH
  shutdown
  echo "rename last version..."
  if [ -f $PACKAGED_NAME.jar ]
    then
      mv $PACKAGED_NAME.jar $PACKAGED_NAME'_'`date +%Y%m%d%H%M%S`.jar
  fi
  echo "copy jar..."
  cp $APP_DEPLOY_PATH/$CODE_DIR/$MODULE_NAME/target/$PACKAGED_NAME.jar $APP_DEPLOY_PATH
  echo "start member@"$PORT
  startup
}

#app shutdown
function shutdown(){
  PID=$(ps -ef | grep $PACKAGED_NAME.jar | grep -v grep | awk '{ print $2 }')
  if [ -z "$PID" ]
  then
    echo Application is already stopped
  else
    echo kill $PID
    kill -9 $PID
  fi
}

#app startup
function startup(){
  echo "startuping"$GIT_BRANCH_NAME"..."
  export JAVA_HOME=$JAVA_HOME
  nohup java -server -Xms512M -Xmx512M -Xss256k \
      -XX:+UseStringDeduplication \
      -XX:+HeapDumpOnOutOfMemoryError \
      -jar $PACKAGED_NAME.jar \
      --server.port=$PORT \
      --spring.profiles.active=$PROFILE \
      > /dev/null_dev 2>&1 &
  echo "startuping success ..."
  echo "打开端口："$PORT"..."
 #如果防火墙开启则打开一下代码
  #firewall-cmd --zone=public --add-port=$PORT/tcp --permanent

}

#package and deploy
function packageanddeploy(){
  echo "begin package"
  package
  echo "end package"
  echo "begin deploy"
  deploy
  echo "end deploy"
}
#pring helpinfo
function help(){
	echo "Usage: ./onekey.sh [gitinit|package|deploy|startup|shutdown|help]"
	echo "gitinit:初始化git设置"
	echo "package:程序打包"
	echo "deploy:程序发布"
	echo "startup:程序启动"
	echo "shutdown:程序关闭"
	echo "help:打印帮助信息"
        echo "packageanddeploy:打包并且部署"
}

case "$1" in
  'gitinit')
    gitinit
    ;;
  'package')
    package
	;;
  'deploy')
    deploy
	;;
  'startup')
	startup
	;;
  'shutdown')
	shutdown
	;;
  'help')
	help
	;;
  'packageanddeploy')
       packageanddeploy
       ;;
  *)
    

esac
exit 0
