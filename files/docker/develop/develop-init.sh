#!/bin/bash

if [ ! $(which wget) ]; then
  echo "Error: wget not installed"
  exit
fi

# 在当前目录下创建develop文件夹作为工作目录
mkdir -p develop

cd develop
wget https://vveicc.github.io/blog/files/docker/develop/docker-compose.yaml
wget https://vveicc.github.io/blog/files/docker/develop/etc/mysql/my.cnf
wget https://vveicc.github.io/blog/files/docker/develop/etc/redis/redis.conf

echo "> 创建宿主机数据卷目录..."
mkdir -p mysql/conf mysql/data
mkdir -p redis/conf redis/data
mkdir -p kafka
mkdir -p zookeeper

mv my.cnf mysql/conf/
mv redis.conf redis/conf/

echo "> 运行容器实例..."
docker compose up -d
