#!/bin/bash

cd /home/git/gitlab
bundle exec rake gitlab:setup RAILS_ENV=production force=yes
bundle exec rake assets:precompile RAILS_ENV=production
chown -R git:git /home/git/
sudo -u git -H "/usr/bin/git" config --global core.autocrlf "input"
