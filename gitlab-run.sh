#!/bin/bash

#gitlab start
exec /etc/init.d/gitlab start

#nginx start
exec nginx

#redis start
sudo -u redis -H redis-server /etc/redis.conf
