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
