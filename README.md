# ** docker-gitlab-cn ** #
Dockerfile是创建docker image的一种常用方式。本文采用dockerfile创建[gitlab-cn image](https://hub.docker.com/r/fanzi/gitlab-cn/)。该image基于Centos Image 7创建，并与mysql image联合使用。
<!-- more -->

## **1. 准备工作** ##

可参考[CentOS7上安装Docker及GitLab](http://fanzicai.github.io/Program/2016/05/25/CentOS7%E4%B8%8A%E5%AE%89%E8%A3%85Docker%E5%8F%8AGitLab.html)一文，先行安装CentOS、Docker。

- Docker MySQL
Oracle官方已提供MySQL的[Docker Image](https://hub.docker.com/r/mysql/mysql-server/)。
```
docker run --restart always --name mysql -e MYSQL_ROOT_PASSWORD=123 -d mysql/mysql-server:latest
```
> 进入mysql控制台
```
docker exec -it mysql /bin/bash
mysql -uroot -p123
```
> 创建git用户及database，本文git用户密码设置为git
```
CREATE USER 'git'@'%' IDENTIFIED BY '$password';
CREATE DATABASE IF NOT EXISTS `gitlabhq_production` DEFAULT CHARACTER SET `utf8` COLLATE `utf8_unicode_ci`;
GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, CREATE TEMPORARY TABLES, DROP, INDEX, ALTER, LOCK TABLES ON `gitlabhq_production`.* TO 'git'@'%';
flush privileges;
\q
```

----------
## **2. Image Build** ##
本Image已上传<https://hub.docker.com/r/fanzi/gitlab-cn/>
```
docker build --rm=true -t fanzi/gitlab-cn .
```
----------
## **3. Image USE** ##
```
docker run -it --detach --restart always --link mysql:mysql -p 80:80 --name gitlab fanzi/gitlab-cn
docker exec -it gitlab /bin/bash -c /home/git/gitlab-init.sh
```