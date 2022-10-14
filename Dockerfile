FROM centos:centos7

ADD ./libs/jdk-8u333-linux-x64.tar.gz /usr/local/
COPY ./libs/libfaketime /home/libfaketime

ENV JAVA_HOME /usr/local/jdk1.8.0_333/
ENV CLASSPATH $JAVA_HOME/jre/lib/ext:$JAVA_HOME/lib/toos.jar
ENV PATH $PATH:$JAVA_HOME/bin

RUN ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && \
    curl -o /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo && \
    yum -y install svn vim net-tools which telnet gcc gcc-c++ make autoconf kde-l10n-Chinese && \
    yum -y reinstall glibc-common && \
    
    localedef -c -f UTF-8 -i zh_CN zh_CN.utf8 && \

    cd /home/libfaketime && make && make install && \
    touch /etc/faketimerc && \

    yum -y remove gcc gcc-c++ make autoconf && \

    yum clean all && \
    rm -rf /var/cache/yum/* /home/libfaketime

ENV FAKETIME_XRESET=1
ENV LD_PRELOAD=/usr/local/lib/faketime/libfaketime.so.1
ENV FAKETIME_NO_CACHE=1
ENV LC_ALL=en_US.utf-8