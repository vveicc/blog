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
