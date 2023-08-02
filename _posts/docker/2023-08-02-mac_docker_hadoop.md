---
layout: post
title: "Mac基于Docker搭建Hadoop集群"
date: 2023-08-02
tags: [Docker, Hadoop]
toc: true
comments: true
author: vveicc
---

在Mac宿主机基于Docker搭建Hadoop分布式集群，仅供学习。

<!-- more -->

---

**运行环境**：

- Intel处理器
- macOS 13.5
- Docker Engine v24.0.2
- Docker Compose v2.19.1
- Hadoop 3.3.6

## 集群规划

|           | hadoop02              | hadoop03                        | hadoop04                       |
|-----------|:----------------------|:--------------------------------|:-------------------------------|
| HDFS      | NameNode<br/>DataNode | <br/>DataNode                   | SecondaryNameNode<br/>DataNode |
| Yarn      | <br/>NodeManager      | ResourceManager<br/>NodeManager | <br/>NodeManager               |
| MapReduce | JobHistoryServer      |                                 |                                |

## 准备配置文件

```text workers
hadoop02
hadoop03
hadoop04
```

```xml core-site.xml
<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<!--
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License. See accompanying LICENSE file.
-->

<!-- Put site-specific property overrides in this file. -->

<configuration>
	<!-- 指定 NameNode 的地址 -->
	<property>
		<name>fs.defaultFS</name>
		<value>hdfs://hadoop02:8020</value>
	</property>
	<!-- 指定 hadoop 数据的存储目录 -->
	<property>
		<name>hadoop.tmp.dir</name>
		<value>/opt/hadoop/data</value>
	</property>
	<!-- 配置 HDFS 网页登录使用的静态用户 -->
	<property>
		<name>hadoop.http.staticuser.user</name>
		<value>root</value>
	</property>

	<!-- 开启回收站功能，并设置回收站中文件存活时间为60分钟 -->
	<property>
		<name>fs.trash.interval</name>
		<value>60</value>
	</property>
</configuration>
```

```xml hdfs-site.xml
<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<!--
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License. See accompanying LICENSE file.
-->

<!-- Put site-specific property overrides in this file. -->

<configuration>
	<!-- nn web 端访问地址-->
	<property>
		<name>dfs.namenode.http-address</name>
		<value>hadoop02:9870</value>
	</property>
	<!-- 2nn web 端访问地址-->
	<property>
		<name>dfs.namenode.secondary.http-address</name>
		<value>hadoop04:9868</value>
	</property>

	<!-- nn 工作线程池并发配置 -->
	<property>
		<name>dfs.namenode.handler.count</name>
		<value>21</value>
	</property>
</configuration>
```

```xml mapred-site.xml
<?xml version="1.0"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<!--
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License. See accompanying LICENSE file.
-->

<!-- Put site-specific property overrides in this file. -->

<configuration>
	<!-- 指定 mapreduce 程序运行在 yarn 上 -->
	<property>
		<name>mapreduce.framework.name</name>
		<value>yarn</value>
	</property>
	<!-- 历史服务器端地址 -->
	<property>
		<name>mapreduce.jobhistory.address</name>
		<value>hadoop02:10020</value>
	</property>
	<!-- 历史服务器 web 端地址 -->
	<property>
		<name>mapreduce.jobhistory.webapp.address</name>
		<value>hadoop02:19888</value>
	</property>
</configuration>
```

```xml yarn-site.xml
<?xml version="1.0"?>
<!--
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License. See accompanying LICENSE file.
-->
<configuration>
	<!-- 指定 mapreduce 走 shuffle -->
	<property>
		<name>yarn.nodemanager.aux-services</name>
		<value>mapreduce_shuffle</value>
	</property>
	<!-- 指定 ResourceManager 的地址-->
	<property>
		<name>yarn.resourcemanager.hostname</name>
		<value>hadoop03</value>
	</property>
	<!-- 环境变量的继承 -->
	<property>
		<name>yarn.nodemanager.env-whitelist</name>
		<value>JAVA_HOME,HADOOP_COMMON_HOME,HADOOP_HDFS_HOME,HADOOP_CONF_DIR,CLASSPATH_PREPEND_DISTCACHE,HADOOP_YARN_HOME,HADOOP_MAPRED_HOME</value>
	</property>
	<!-- 开启日志聚集功能 -->
	<property>
		<name>yarn.log-aggregation-enable</name>
		<value>true</value>
	</property>
	<!-- 设置日志聚集服务器地址 -->
	<property>
		<name>yarn.log.server.url</name>
		<value>http://hadoop02:19888/jobhistory/logs</value>
	</property>
	<!-- 设置日志保留时间为 7 天 -->
	<property>
		<name>yarn.log-aggregation.retain-seconds</name>
		<value>604800</value>
	</property>

	<!-- 选择调度器，默认容量调度器 -->
	<property>
		<name>yarn.resourcemanager.scheduler.class</name>
		<value>org.apache.hadoop.yarn.server.resourcemanager.scheduler.capacity.CapacityScheduler</value>
	</property>
	<!-- ResourceManager 处理调度器请求的线程数量，默认 50 -->
	<!-- 如果提交的任务数大于 50，可以增加该值，但是不能超过 3 台 * 4 线程 = 12 线程(去除其他应用程序实际不能超过 8) -->
	<property>
		<name>yarn.resourcemanager.scheduler.client.thread-count</name>
		<value>8</value>
	</property>
	<!-- 是否让 yarn 自动检测硬件进行配置，默认是 false -->
	<!-- 如果该节点有很多其他应用程序，建议手动配置；如果该节点没有其他应用程序，可以采用自动 -->
	<property>
		<name>yarn.nodemanager.resource.detect-hardware-capabilities</name>
		<value>false</value>
	</property>
	<!-- 是否将虚拟核数当作 CPU 核数，默认是 false，采用物理 CPU 核数 -->
	<property>
		<name>yarn.nodemanager.resource.count-logical-processors-as-cores</name>
		<value>false</value>
	</property>
	<!-- 虚拟核数和物理核数乘数，默认是 1.0 -->
	<property>
		<name>yarn.nodemanager.resource.pcores-vcores-multiplier</name>
		<value>1.0</value>
	</property>
	<!-- NodeManager 使用内存数，默认 8G，修改为 4G 内存 -->
	<property>
		<name>yarn.nodemanager.resource.memory-mb</name>
		<value>4096</value>
	</property>
	<!-- NodeManager 的 CPU 核数，不按照硬件环境自动设定时默认是 8 个，修改为 4 个 -->
	<property>
		<name>yarn.nodemanager.resource.cpu-vcores</name>
		<value>4</value>
	</property>
	<!-- 容器最小内存，默认 1G -->
	<property>
		<name>yarn.scheduler.minimum-allocation-mb</name>
		<value>1024</value>
	</property>
	<!-- 容器最大内存，默认 8G，修改为 2G -->
	<property>
		<name>yarn.scheduler.maximum-allocation-mb</name>
		<value>2048</value>
	</property>
	<!-- 容器最小 CPU 核数，默认 1 个 -->
	<property>
		<name>yarn.scheduler.minimum-allocation-vcores</name>
		<value>1</value>
	</property>
	<!-- 容器最大 CPU 核数，默认 4 个，修改为 2 个 -->
	<property>
		<name>yarn.scheduler.maximum-allocation-vcores</name>
		<value>2</value>
	</property>
	<!-- 虚拟内存检查，默认打开，修改为关闭 -->
	<property>
		<name>yarn.nodemanager.vmem-check-enabled</name>
		<value>false</value>
	</property>
	<!-- 虚拟内存和物理内存设置比例，默认 2.1 -->
	<property>
		<name>yarn.nodemanager.vmem-pmem-ratio</name>
		<value>2.1</value>
	</property>

	<!-- 开启 uber 模式，优化小文件计算，默认关闭 -->
	<property>
		<name>mapreduce.job.ubertask.enable</name>
		<value>true</value>
	</property>
	<!-- uber 模式中最大的 map 数量，仅可向下修改 -->
	<property>
		<name>mapreduce.job.ubertask.maxmaps</name>
		<value>9</value>
	</property>
	<!-- uber 模式中最大的 reduce 数量，仅可向下修改 -->
	<property>
		<name>mapreduce.job.ubertask.maxreduces</name>
		<value>1</value>
	</property>
	<!-- uber 模式中最大的输入数据量，默认使用 dfs.blocksize 的值，仅可向下修改 -->
	<property>
		<name>mapreduce.job.ubertask.maxbytes</name>
		<value></value>
	</property>
</configuration>
```

## 编写工具脚本

```shell jpsall
#!/bin/bash

for host in hadoop02 hadoop03 hadoop04
do
	echo "> $host"
	ssh -o StrictHostKeyChecking=no $host $JAVA_HOME/bin/jps
done
```

```shell ihadoop.sh
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
```

## Dockerfile

基于 [bitnami/java:1.8](https://github.com/bitnami/containers/blob/main/bitnami/java/1.8/debian-11/Dockerfile) 构建Docker镜像。

```dockerfile Dockerfile
FROM bitnami/java:1.8
MAINTAINER vveicc

ARG HADOOP_VERSION=3.3.6

WORKDIR /root

ENV HADOOP_HOME /opt/hadoop

RUN echo "==> install ssh..." && \
    sed -i s@/deb.debian.org/@/mirrors.aliyun.com/@g /etc/apt/sources.list && \
    sed -i s@/security.debian.org/@/mirrors.aliyun.com/debian-security@g /etc/apt/sources.list && \
    apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends ssh && \
    \
    echo "==> setup ssh..." && \
    echo "\n/etc/init.d/ssh start >> /dev/null" >> ~/.bashrc && \
    ssh-keygen -t rsa -P '' -f ~/.ssh/id_rsa && \
    cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys && \
    chmod 0600 ~/.ssh/authorized_keys && \
    \
    echo "==> download hadoop..." && \
    mkdir -p $HADOOP_HOME && \
    wget --no-check-certificate https://mirrors.tuna.tsinghua.edu.cn/apache/hadoop/common/hadoop-$HADOOP_VERSION/hadoop-$HADOOP_VERSION.tar.gz && \
    tar -zxf hadoop-$HADOOP_VERSION.tar.gz --strip-components 1 -C $HADOOP_HOME && \
    \
    echo "==> download configuration & scripts..." && \
    wget https://vveicc.github.io/blog/files/docker/hadoop/hadoop.tar.gz && \
    tar -zxf hadoop.tar.gz && \
    mv etc/hadoop/* $HADOOP_HOME/etc/hadoop/ && \
    mv scripts/* /usr/local/bin/ && \
    \
    echo "==> setup env..." && \
    echo "export JAVA_HOME=$JAVA_HOME" >> /etc/profile.d/iprofile.sh && \
    echo "export HADOOP_HOME=$HADOOP_HOME" >> /etc/profile.d/iprofile.sh && \
    echo "export PATH=\$PATH:\$JAVA_HOME/bin:\$HADOOP_HOME/bin:\$HADOOP_HOME/sbin" >> /etc/profile.d/iprofile.sh && \
    echo "\nif [ -f /etc/profile ]; then\n\t. /etc/profile\nfi" >> ~/.bashrc && \
    echo "\nexport SHELL=/bin/bash" >> ~/.bashrc && \
    echo "\nexport LS_OPTIONS='--color=auto'" >> ~/.bashrc && \
    echo "eval \"\`dircolors\`\"" >> ~/.bashrc && \
    echo "alias ls='ls \$LS_OPTIONS'" >> ~/.bashrc && \
    echo "alias ll='ls \$LS_OPTIONS -lA'" >> ~/.bashrc && \
    \
    echo "==> setup hadoop env..." && \
    echo "export HDFS_NAMENODE_OPTS=\"-Dhadoop.security.logger=INFO,RFAS -Xmx1024m\"" >> $HADOOP_HOME/etc/hadoop/hadoop-env.sh && \
    echo "export HDFS_DATANODE_OPTS=\"-Dhadoop.security.logger=ERROR,RFAS -Xmx1024m\"" >> $HADOOP_HOME/etc/hadoop/hadoop-env.sh && \
    echo "export JAVA_HOME=$JAVA_HOME" >> $HADOOP_HOME/etc/hadoop/hadoop-env.sh && \
    echo "export HADOOP_MAPRED_HOME=$HADOOP_HOME" >> $HADOOP_HOME/etc/hadoop/hadoop-env.sh && \
    echo "export HDFS_NAMENODE_USER=root" >> $HADOOP_HOME/etc/hadoop/hadoop-env.sh && \
    echo "export HDFS_DATANODE_USER=root" >> $HADOOP_HOME/etc/hadoop/hadoop-env.sh && \
    echo "export HDFS_SECONDARYNAMENODE_USER=root" >> $HADOOP_HOME/etc/hadoop/hadoop-env.sh && \
    echo "export YARN_RESOURCEMANAGER_USER=root" >> $HADOOP_HOME/etc/hadoop/hadoop-env.sh && \
    echo "export YARN_NODEMANAGER_USER=root" >> $HADOOP_HOME/etc/hadoop/hadoop-env.sh && \
    \
    echo "==> clean up..." && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives && \
    rm -rf hadoop-$HADOOP_VERSION.tar.gz hadoop.tar.gz etc scripts

CMD ["/bin/bash"]

# NameNode WEB UI 端口
EXPOSE 9870
# DataNode WEB UI 端口
EXPOSE 9864
# SecondaryNameNode WEB UI 端口
EXPOSE 9868
# 历史服务器 WEB UI 端口
EXPOSE 19888
# Yarn WEB UI 端口
EXPOSE 8088
```

## docker-compose.yaml

使用静态IP，便于在宿主机访问容器，如果子网IP如有冲突，需要更改为未占用的IP。

```yaml docker-compose.yaml
version: "3.1"

networks:
  cluster:
    ipam:
      driver: default
      config:
        - subnet: "172.18.0.0/28"
          gateway: "172.18.0.1"

services:
  hadoop02:
    image: vveicc/hadoop:3.3.6
    hostname: hadoop02
    container_name: hadoop02
    restart: always
    stdin_open: true
    tty: true
    networks:
      cluster:
        ipv4_address: 172.18.0.2
    volumes:
      - ./hadoop02/hadoop/data:/opt/hadoop/data
      - ./hadoop02/hadoop/logs:/opt/hadoop/logs

  hadoop03:
    image: vveicc/hadoop:3.3.6
    hostname: hadoop03
    container_name: hadoop03
    restart: always
    stdin_open: true
    tty: true
    networks:
      cluster:
        ipv4_address: 172.18.0.3
    volumes:
      - ./hadoop03/hadoop/data:/opt/hadoop/data
      - ./hadoop03/hadoop/logs:/opt/hadoop/logs

  hadoop04:
    image: vveicc/hadoop:3.3.6
    hostname: hadoop04
    container_name: hadoop04
    restart: always
    stdin_open: true
    tty: true
    networks:
      cluster:
        ipv4_address: 172.18.0.4
    volumes:
      - ./hadoop04/hadoop/data:/opt/hadoop/data
      - ./hadoop04/hadoop/logs:/opt/hadoop/logs
```

## 快速部署脚本

编写快速部署脚本：

```shell init.sh
#!/bin/bash

if [ ! $(which wget) ]; then
  echo "Error: wget not installed"
  exit
fi

# 在当前目录下创建hadoop文件夹作为工作目录
mkdir -p hadoop

cd hadoop
wget https://vveicc.github.io/blog/files/docker/hadoop/Dockerfile
wget https://vveicc.github.io/blog/files/docker/hadoop/docker-compose.yaml

echo "> 构建镜像..."
docker build -t vveicc/hadoop:3.3.6 .

echo "> 创建宿主机数据卷目录..."
for host in hadoop02 hadoop03 hadoop04
do
       mkdir -p $host/hadoop/data
       mkdir -p $host/hadoop/logs
done

echo "> 运行容器实例..."
docker compose up -d
```

在 Mac 上通过脚本快速部署：

```shell
wget https://vveicc.github.io/blog/files/docker/hadoop/init.sh
bash init.sh
```

## 启动Hadoop集群

查看 Docker 容器：

```shell
cd hadoop
docker compose ps
```

进入 Docker 容器：

```shell
docker exec -it hadoop02 bash
```

第一次启动集群需要先格式化 NameNode ：

```shell
root@hadoop02:~# ihadoop.sh format
```

启动 Hadoop 集群：

```shell
root@hadoop02:~# ihadoop.sh start
```

查看集群 Java 进程：

```shell
root@hadoop02:~# jpsall
```

如果看到的进程信息与 [集群规划](#集群规划) 一致，说明 Hadoop 集群启动成功。

运行 `WordCount` 示例程序，测试验证集群是否正常：

```shell
root@hadoop02:~# hdfs dfs -mkdir /input
root@hadoop02:~# hdfs dfs -put $HADOOP_HOME/README.txt /input/
root@hadoop02:~# hdfs dfs -ls /input
root@hadoop02:~# hadoop jar $HADOOP_HOME/share/hadoop/mapreduce/hadoop-mapreduce-examples-3.3.6.jar wordcount /input /output
```

## Mac宿主机访问集群

`Docker Desktop for Mac` 没有提供从宿主的macOS通过容器IP访问容器的方式。

需要通过 [mac-docker-connector](https://github.com/wenjunxiao/mac-docker-connector) 将Mac宿主机与Docker容器网络打通。

如果在网络打通过程中遇到问题，可以参考 [Mac宿主机与Docker容器网络打通](mac_docker_connector) 解决。

网络打通后，在 `/etc/hosts` 文件中添加域名IP映射：

```shell
172.18.0.2 hadoop02
172.18.0.3 hadoop03
172.18.0.4 hadoop04
```

在宿主机访问 HDFS：[hadoop02:9870](http://hadoop02:9870)

在宿主机访问 Yarn：[hadoop03:8088](http://hadoop03:8088)
