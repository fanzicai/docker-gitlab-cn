#!/bin/bash

#gitlab start
/etc/init.d/gitlab start &

#nginx start
nginx &

#sshd start
/usr/sbin/sshd

#redis start
sudo -u redis -H redis-server /etc/redis.conf
