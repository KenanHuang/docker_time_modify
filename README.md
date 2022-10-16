# Motivation

As we all know,changing time in a container is almost impossible due to docker's isolation mechanism.

You may have seen the following notice:

```bash
[root@1b4943b5b4dd /]# date -s "2022-10-25"
date: cannot set date: Operation not permitted
Tue Oct 25 00:00:00 UTC 2022
[root@1b4943b5b4dd /]# 
```

Of cause,you can add --cap-add SYS_TIME in command when you run the container.But this way may be unstable and may affect the host.

You may have seen the following situations:

```bash
(base) ➜  ~ docker run -itd --cap-add SYS_TIME --name testos centos:centos7 /bin/bash
b1ad49dbdbbb5c36a1f93e3f31164c872b81be9b1a16de08bbc1136e46428b14
(base) ➜  ~ docker exec -it testos /bin/bash                                         
[root@b1ad49dbdbbb /]# date -s "2022-10-25" && date
Tue Oct 25 00:00:00 UTC 2022
Tue Oct 25 00:00:00 UTC 2022
[root@b1ad49dbdbbb /]# date
Tue Oct 25 00:00:03 UTC 2022
[root@b1ad49dbdbbb /]# date
Tue Oct 25 00:00:06 UTC 2022
[root@b1ad49dbdbbb /]# date
Fri Oct 14 08:49:33 UTC 2022 #the time change back automatically after few seconds 
[root@b1ad49dbdbbb /]# 
```

So I think being able to freely modify the time in the container would help a lot of people.This would be great for simulating scenarios at specific times.

# Method

Thanks to [wolfcw/libfaketime](https://github.com/wolfcw/libfaketime) .This is a feasible approach to generate a fake time and intercepts all system call programs use to retrieve the time and date(detailed in [libfaketime/README at master · wolfcw/libfaketime (github.com)](https://github.com/wolfcw/libfaketime/blob/master/README)).

Version v2:latest

I review the introduction of libfaketime.I think here is another way to change time.

steps as follow:

1. compile libfaketime with FAKETIME_COMPILE_CFLAGS="-DFAKE_SETTIME"(i.e. make FAKETIME_COMPILE_CFLAGS="-DFAKE_SETTIME" && make install)

2. create a file for storing time offset.(e.g. echo "+0" > /etc/myfaketime.rc)

3. add LD_PRELOAD=/usr/local/lib/faketime/libfaketime.so.1 FAKETIME_TIMESTAMP_FILE=/etc/myfaketime.rc FAKETIME_UPDATE_TIMESTAMP_FILE=1 FAKETIME_NO_CACHE=1 as Enviroment variables

I also provide pure version of dockerfile(i.e. remove java svn and others,only keep faketime support)

~~Version v1:2022-10-14~~

~~In order to achieve the same modification effect as the native command, I only used the system-wide method.~~

~~I do the following steps to achieve the effect.~~

1. ~~clone [git@github.com](mailto:git@github.com):wolfcw/libfaketime.git~~

2. ~~copy the libfaketime lib into image~~

3. ~~compile and install it via "make && make install"~~

4. ~~add LD_PRELOAD=/usr/local/lib/faketime/libfaketime.so.1 FAKETIME_NO_CACHE=1 FAKETIME_XRESET=1 as Environment Variables~~

5. ~~Finally,changing the content in /etc/faketimerc can affect the output of date~~

~~More details in Dockerfile (btw:I also install the java,svn and chinese langpack in image because I`m a developer in China^_^.So you can change that as you need.)~~

# Usage

Step1:Clone

```bash
git clone git@github.com:KenanHuang/docker_time_modify.git
```

Step2:download the jdk and clone the libfaketime 

Step3:put jdk and libfaketime into libs.the contents in libs as following:

```bash
(base) ➜  docker_time_modify git:(main) ls -l libs
total 289808
-rw-r--r--@  1 conan  staff  148003421 Oct 14 12:02 jdk-8u333-linux-x64.tar.gz
drwxr-xr-x  17 conan  staff        544 Oct 12 15:43 libfaketime
```

Step4:build image

```bash
docker build -t centos7_faketime:2.0 -f ./Dockerfile-pure-v2 .
```

Step5:run container

```bash
docker run -it --rm centos7_faketime:2.0 /bin/bash
```

Step6:do whatever you want

```bash
(base) ➜  docker_time_modify git:(main) ✗ docker run -itd --name tstest centos7_faketime:2.0 /bin/bash
fa99c9cfdbb333df71c60f71538ee11f8594ebec7e0
(base) ➜  docker_time_modify git:(main) ✗ docker exec -it tstest /bin/bash
[root@fa99c9cfdbb3 /]# date
Sun Oct 16 05:30:27 UTC 2022
[root@fa99c9cfdbb3 /]# date -s "2099-11-12 12:00:00"
Thu Nov 12 12:00:00 UTC 2099
[root@fa99c9cfdbb3 /]# date
Thu Nov 12 12:00:01 UTC 2099
[root@fa99c9cfdbb3 /]# exit
(base) ➜  docker_time_modify git:(main) ✗ docker exec -it tstest /bin/bash
[root@fa99c9cfdbb3 /]# date
Thu Nov 12 12:00:12 UTC 2099
[root@fa99c9cfdbb3 /]# date -s "1993-10-25 08:00:00"
Mon Oct 25 08:00:00 UTC 1993
[root@fa99c9cfdbb3 /]# date
Mon Oct 25 08:00:01 UTC 1993
```

~~version v1
[root@df551f8e0bc4 /]# which java
/usr/local/jdk1.8.0_333/bin/java
[root@df551f8e0bc4 /]# which svn
/usr/bin/svn
[root@df551f8e0bc4 /]# date
Fri Oct 14 17:41:31 CST 2022
[root@df551f8e0bc4 /]# echo "+5h" > /etc/faketimerc 
[root@df551f8e0bc4 /]# date
Fri Oct 14 22:41:44 CST 2022~~

## How to change time in Container

In latest version.You just need to use "date -s " command to change time.And use "echo "+0" > /etc/myfaketime.rc" to restore time.

#### demo:

```bash
(base) ➜  docker_time_modify git:(main) ✗ docker exec -it tstest /bin/bash
[root@fa99c9cfdbb3 /]# date
Sun Oct 16 05:30:27 UTC 2022
[root@fa99c9cfdbb3 /]# date -s "2099-11-12 12:00:00"
Thu Nov 12 12:00:00 UTC 2099
[root@fa99c9cfdbb3 /]# date
Thu Nov 12 12:00:01 UTC 2099
[root@fa99c9cfdbb3 /]# echo "+0" > /etc/myfaketime.rc
[root@fa99c9cfdbb3 /]# date
Sun Oct 16 05:30:33 UTC 2022
```

~~version v1:~~

#### ~~Parameters you need to know in advance~~

~~The multipliers "m", "h", "d" and "y" can be used to specify the offset in
  minutes, hours, days and years (365 days each), respectively. -- as described in [wolfcw/libfaketime](https://github.com/wolfcw/libfaketime)~~

~~/etc/faketimerc  is used to store the offset of fake time.So you just need to change it to get different time.~~

~~demo:~~

~~(base) ➜  ~ docker run -it --rm centos7_faketime_java_svn:1.0 /bin/bash
[root@87238b4bc443 /]# date
Fri Oct 14 17:31:50 CST 2022
[root@87238b4bc443 /]# echo "+1h" > /etc/faketimerc && date # change the time to one hour later
Fri Oct 14 18:32:02 CST 2022
[root@87238b4bc443 /]# echo "+2d" > /etc/faketimerc && date
Sun Oct 16 17:32:08 CST 2022
[root@87238b4bc443 /]# echo "-1y" > /etc/faketimerc && date
Thu Oct 14 17:32:13 CST 2021
[root@87238b4bc443 /]# echo "+0" > /etc/faketimerc && date # restore time
Fri Oct 14 17:32:17 CST 2022
[root@87238b4bc443 /]# date
Fri Oct 14 17:32:19 CST 2022~~

# Acknowledgements

Thank Wolfgang Hommel develop such fantastic job.Here is the link of libfaketime:[https://github.com/wolfcw/libfaketime](https://github.com/wolfcw/libfaketime)

# PS:

Please give a star ⭐️ ! If this project could help you.Thanks a lot ! ^_^
