#!/bin/bash

#####################################################
# Usage: Asynchronous task unified scheduling script
# File Name: demo.sh
# Author: annhe  
# Mail: i@annhe.net
# Created Time: 2017-04-21 16:08:38
# Google Translate Schirrms 2022-03-28
#####################################################

d=`cd $(dirname $0);pwd`
cd $d
ds=`date +%Y%m%d-%H%M%S`

LOGDIR=logs
[ ! -d $LOGDIR ] && mkdir $LOGDIR
TASKDIR=tasks
mainlog=$LOGDIR/`echo $0 |awk -F'/' '{print $NF}'`.log
tasklog=$LOGDIR/$SCRIPT_NAME.log
SCRIPT=$TASKDIR/$SCRIPT_NAME
# 启动子脚本，必须要使用&和指定输出(只好是定向到/dev/null) 传递日志路径给脚本
# To start a subscript, you must use & and specify the output 
# (it has to be directed to /dev/null) Pass the log path to the script 
./$SCRIPT $tasklog &>>$mainlog  &

LOG="$ds - $SCRIPT Stared - $ID - $TITLE"
echo $LOG
echo $LOG >> $mainlog
sed -i '/^$/d' $mainlog
