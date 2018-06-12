#！/bin/bash
# Date env
CDATE=`date "+%Y-%m-%d"`
CTIME=`date "+%H-%M-%S"`
# Shell Env
SHELL_NAME="deploy.sh"
SHELL_DIR="/tmp/"
SHELL_LOG="${SHELL_DIR}/${SHELL_NAME}.log"

# node list
NODE_LIST="192.168.5.124 192.168.5.125"

#Code Env
PRO_NAME="web-demo"
CODE_DIR="/deploy/code/web-demo"
CONFIG_DIR="/deploy/config/web-demo"
TMP_DIR="/deploy/tmp"
TAR_DIR="/deploy/tar"
LOCK_FILE="/tmp/deploy.lock"
VER_FILE="/deploy/ver/ver.txt"

usage(){
	
	echo_green "Usage: $0 { deploy | rollback [ list | version ] | del [ file ] }"

}
echo_red(){
	echo -e "\033[31m$1\033[0m" 
	
}
echo_green(){
	
	echo -e "\033[32m$1\033[0m" 
}
write_log(){
 	LOGINFO=$1
	echo "${CDATE} ${CTIME}: ${SHELL_NAME} : ${LOGINFO}" >> ${SHELL_LOG}
	
}
shell_lock(){
	echo "running" >> ${LOCK_FILE}
}
shell_unlock(){
	rm -f ${LOCK_FILE}
}
code_get(){
	write_log "code_get";
	cd $CODE_DIR && git pull
	/bin/cp -r ${CODE_DIR} ${TMP_DIR} 
	API_VER=`git show | grep commit | cut -d ' ' -f2|cut -c 1-6`
}
code_build(){
	echo "code_build"

}
code_config(){
	write_log "code_config"
	/bin/cp -r ${CONFIG_DIR}/base/* ${TMP_DIR}/${PRO_NAME}
	PKG_NAME="$PRO_NAME"_"$API_VER"_"${CDATE}_${CTIME}"
	cd ${TMP_DIR} && mv ${PRO_NAME} ${PKG_NAME}
	
}
code_tar(){
	write_log "code_tar"
	cd ${TMP_DIR} && tar czf ${PKG_NAME}.tar.gz ${PKG_NAME}
	write_log "${PKG_NAME}.tar.gz"
}
code_scp(){
	write_log code_scp
	for node in $NODE_LIST;
		do
		    /bin/scp ${TMP_DIR}/${PKG_NAME}.tar.gz $node:/opt/webroot
	done	
}
code_deploy(){
	write_log "code_get_deploy"
	for node in $NODE_LIST;
                do
		    ssh $node  "cd /opt/webroot/ && tar zxf ${PKG_NAME}.tar.gz"
		    ssh $node "rm -rf /opt/webroot/web-demo && ln -s /opt/webroot/${PKG_NAME} /opt/webroot/web-demo"
        done
	/bin/scp ${CONFIG_DIR}/other/192.168.5.124.crontab.xml 192.168.5.124:/opt/webroot/web-demo/crontab.xml
	echo ${PKG_NAME} >> /deploy/ver/ver.txt

}

code_test(){
	echo "code_test"
}
rollback_list(){

	cat $VER_FILE
}
rollback_file(){
	FILE=$1
	for NODE in $NODE_LIST
		do
		    ssh $NODE "rm -fr /opt/webroot/web-demo && ln -s /opt/webroot/$FILE /opt/webroot/web-demo"
		done
}
rollback_action(){
	VER_NUM=$1
	if [ -z $VER_NUM ];then
		echo_red "syntax error"
		usage;
	else 
	   grep $VER_NUM $VER_FILE && RV=$?
	   if [ "$RV" = 0 ];then
                echo_green "$VER_NUM is existence"
                echo "start rollback......"
                rollback_file $VER_NUM;
            else         
                echo "$VER_NUM is inexistence, please check files" 
                usage;
	   fi
	fi 
}
rollback(){
	OPTIONS=$1
	case $OPTIONS in
		list)
			rollback_list;
			;;
		*)
			rollback_action $OPTIONS;
			;;
	esac
}
#del node file
del_file(){
	FILE=$1
	if [ -z $FILE ];then
		echo "syntax error"
	        usage;
		exit;
	else
		grep $FILE $VER_FILE && RV=$?
		if [ "$RV" = 0 ];then
			for NODE in $NODE_LIST
	    			do
				     ssh $NODE "rm -fr /opt/webroot/$FILE /opt/webroot/$FILE.tar.gz"
	    			done
		else
			echo "The file is inexistence"
		
		fi
		sed -i "/$FILE/d" $VER_FILE
	fi
}
del(){
	OPTIONS=$1
	case $OPTIONS in
		list)
			rollback_list;
                        ;;
		*)
			del_file $OPTIONS;
	esac

}
main(){
	if [ -f ${LOCK_FILE} ];then
		echo "Deploy is running" && exit;
	fi
	DEPLOY_METHOD=$1
	OPTION_REV=$2
	case $DEPLOY_METHOD in
		deploy)
			shell_lock;
			code_get;
			code_build;
			code_config;
			code_tar;
			code_scp;
			code_deploy;
			code_test;
			shell_unlock;
			;;
		rollback)
			shell_lock;
			rollback $OPTION_REV;
			shell_unlock;
			;;
		del)
			shell_lock;
			del $OPTION_REV;
			shell_unlock;
			;;
		*)
			usage;
       esac
}
main $1 $2
