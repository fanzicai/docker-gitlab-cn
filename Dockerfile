FROM centos:centos7
MAINTAINER fanzi "fanzicai@yahoo.com"

RUN yum -y install wget \
 && wget http://repo.mysql.com//mysql57-community-release-el7-8.noarch.rpm \
 && rpm -Uvh mysql57-community-release-el7-8.noarch.rpm \
 && yum -y update \
 && yum -y group install "development tools" \
 && yum -y install epel-release \
 && yum -y install sudo vim cmake mysql mysql-devel openssh-server go ruby redis nodejs nginx readline-devel gdbm-devel openssl-devel expat-devel sqlite-devel libyaml-devel libffi-devel libxml2-devel libxslt-devel libicu-devel python-devel xmlto logwatch perl-ExtUtils-CBuilder

RUN adduser --system --shell /bin/bash --comment 'GitLab' --create-home --home-dir /home/git/ git \
 && chmod -R go+rx /home/git

WORKDIR /home/git
RUN wget https://www.kernel.org/pub/software/scm/git/git-2.8.3.tar.gz \
 && wget https://cache.ruby-lang.org/pub/ruby/2.3/ruby-2.3.1.tar.gz \
 && wget https://storage.googleapis.com/golang/go1.5.3.linux-amd64.tar.gz \
 && wget  https://gitlab.com/larryli/gitlab/repository/archive.tar.gz?ref=v8.8.0.zh1 \
 && tar xvf git-2.8.3.tar.gz \
 && tar xvf ruby-2.3.1.tar.gz \
 && tar xvf go1.5.3.linux-amd64.tar.gz -C /usr/local/ \
 && tar xvf archive.tar.gz?ref=v8.8.0.zh1 \
 && mv gitlab-v8.8.0.zh1* gitlab \
 && ln -sf /usr/local/go/bin/{go,godoc,gofmt} /usr/bin/ \
# Git install
 && cd git-2.8.3 \
 && ./configure --prefix=/usr \
 && make \
 && make install \
# Ruby update
 && cd ../ruby-2.3.1/ \
 && ./configure --prefix=/usr --disable-install-rdoc \
 && make \
 && make install \
# Bundler
 && gem sources --add https://ruby.taobao.org/ --remove https://rubygems.org/ \
 && gem install bundler \
 && bundle config mirror.https://rubygems.org https://ruby.taobao.org \
# Redis config & start
 && echo 'unixsocket /var/run/redis/redis.sock' >> /etc/redis.conf \
 && echo 'unixsocketperm 770' >> /etc/redis.conf \
 && chown redis:redis /var/run/redis \
 && chmod 755 /var/run/redis \
 && usermod -aG redis git \
 && (redis-server /etc/redis.conf &)

# GitLab
WORKDIR /home/git/gitlab/
RUN cp config/gitlab.yml.example config/gitlab.yml \
 && cp config/secrets.yml.example config/secrets.yml \
 && chmod 0600 config/secrets.yml \
 && chown -R git log/ \
 && chown -R git tmp/ \
 && chmod -R u+rwX,go-w log/ \
 && chmod -R u+rwX tmp/ \
 && chmod -R u+rwX tmp/pids/ \
 && chmod -R u+rwX tmp/sockets/ \
 && mkdir public/uploads/ \
 && chmod 0700 public/uploads \
 && chmod -R u+rwX builds/ \
  && chmod -R u+rwX shared/artifacts/ \
 && cp config/unicorn.rb.example config/unicorn.rb \
 && cp config/initializers/rack_attack.rb.example config/initializers/rack_attack.rb \
 && git config --global core.autocrlf input \
 && git config --global gc.auto 0 \
 && cp config/resque.yml.example config/resque.yml \
 && cp config/database.yml.mysql config/database.yml \
 && sed -i 's/"secure password"/git/' config/database.yml \
 && sed -i 's/# host: localhost/host: mysql/' config/database.yml \
 && sed -i 's/rubygems.org/ruby.taobao.org/' Gemfile \
 && bundle install --deployment --without development test postgres aws \
 && bundle exec rake gitlab:shell:install REDIS_URL=unix:/var/run/redis/redis.sock RAILS_ENV=production \
 && chown -R git:git /home/git/repositories/ \
 && chmod -R ug+rwX,o-rwx /home/git/repositories/ \
 && chmod -R ug-s /home/git/repositories/ \
 && find /home/git/repositories/ -type d -print0 | xargs -0 chmod g+s \
 && chmod 700 /home/git/gitlab/public/uploads \
 && chown -R git:git config/ log/ \
# GitLab rc.file
 && cp lib/support/init.d/gitlab /etc/init.d/gitlab

# Nginx config
WORKDIR /home/git/gitlab/
RUN mkdir /etc/nginx/sites-available \
 && mkdir /etc/nginx/sites-enabled \
 && cp lib/support/nginx/gitlab /etc/nginx/sites-available/gitlab \
 && ln -s /etc/nginx/sites-available/gitlab /etc/nginx/sites-enabled/gitlab \
 && sed -i '20a\  server 127.0.0.1:8080;' /etc/nginx/sites-available/gitlab \
 && sed -i '35,54d' /etc/nginx/nginx.conf \
 && sed -i '33a\    include /etc/nginx/sites-enabled/*;' /etc/nginx/nginx.conf

WORKDIR /home/git
# Gitlab-Workhorse
RUN git clone https://gitlab.com/gitlab-org/gitlab-workhorse.git \
 && cd gitlab-workhorse/ \
 && git checkout v0.7.2 \
 && make \
 && sshd-keygen

EXPOSE 80 22

VOLUME ["/tmp/gitlab-cn"]

ADD ./gitlab-init.sh /home/git/gitlab-init.sh
ADD ./gitlab-run.sh /home/git/gitlab-run.sh

RUN chmod +x /home/git/gitlab-init.sh
RUN chmod +x /home/git/gitlab-run.sh

ENTRYPOINT ["/home/git/gitlab-run.sh"]
