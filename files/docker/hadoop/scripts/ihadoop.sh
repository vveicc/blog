#!/bin/bash

usage="Usage: ihadoop.sh (start|stop|restart|cleanup|format)"

# 检查参数个数
if [ $# -ne 1 ]
then
	echo -e "Error: 请输入一个参数!\n$usage"
	exit
fi

function stop()
{
	echo -e "> 关闭 hadoop 集群..."
	echo -e "> stop historyserver..."
	ssh -o StrictHostKeyChecking=no hadoop02 "$HADOOP_HOME/bin/mapred --daemon stop historyserver"
	echo -e "> stop yarn..."
	ssh -o StrictHostKeyChecking=no hadoop03 "$HADOOP_HOME/sbin/stop-yarn.sh"
	echo -e "> stop dfs..."
	ssh -o StrictHostKeyChecking=no hadoop02 "$HADOOP_HOME/sbin/stop-dfs.sh"
}

function start()
{
	echo -e "> 启动 hadoop 集群..."
	echo -e "> start dfs..."
	ssh -o StrictHostKeyChecking=no hadoop02 "$HADOOP_HOME/sbin/start-dfs.sh"
	echo -e "> start yarn..."
	ssh -o StrictHostKeyChecking=no hadoop03 "$HADOOP_HOME/sbin/start-yarn.sh"
	echo -e "> start historyserver..."
	ssh -o StrictHostKeyChecking=no hadoop02 "$HADOOP_HOME/bin/mapred --daemon start historyserver"
}

function cleanup()
{
	echo -e "> 清理 data 和 logs 目录..."
	for host in hadoop02 hadoop03 hadoop04
	do
		echo "> 清理 $host..."
		ssh -o StrictHostKeyChecking=no $host "rm -rf $HADOOP_HOME/data/* $HADOOP_HOME/logs/*"
	done
}

function format()
{
	ssh -o StrictHostKeyChecking=no hadoop02 "$HADOOP_HOME/bin/hdfs namenode -format"
}

function sleep3s()
{
	echo -e "> sleep 3s..."
	sleep 3s
}

case $1 in
"stop")
	stop
;;
"start")
	start
;;
"restart")
	stop && echo && sleep3s && echo && start
;;
"cleanup")
	cleanup
;;
"format")
	cleanup && format
;;
*)
	echo -e "Error: 请输入正确的参数!\n$usage"
;;
esac
