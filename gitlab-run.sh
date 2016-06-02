#!/bin/bash

#gitlab start
/etc/init.d/gitlab start &

#nginx start
nginx &

#redis start
sudo -u redis -H redis-server /etc/redis.conf
