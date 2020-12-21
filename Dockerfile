FROM ruby:2.7.1

MAINTAINER Jihane Najdi <jnajdi@vt.edu>

# Default environment
ARG RAILS_ENV='development'
ARG ODSA_BRANCH='master'
ARG LTI_BRANCH='master'

ENV TZ=America/New_York
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Setting the default opendsa Makefile variable ODSA_ENV to 'PROD' and PYTHON to 'python'
ENV PYTHON='python'
ENV ODSA_ENV='PROD'

ENV GEM_HOME /usr/local/bundle
ENV PATH $GEM_HOME/bin:$PATH
ENV BUNDLER_VERSION 2.1.4

ENV RAILS_ENV=$RAILS_ENV
ENV ODSA_BRANCH=$ODSA_BRANCH
ENV LTI_BRANCH=$LTI_BRANCH

RUN apt-get update -qq \
    && apt-get install -y apt-utils build-essential libpq-dev lsof vim cron curl \
    && apt-get install -y nodejs npm python3-pip git-core zlib1g-dev libssl-dev libreadline-dev libyaml-dev libevent-dev libsqlite3-dev libxml2-dev libxml2 libxslt1-dev libffi-dev libxslt-dev sqlite3 dkms python-dev python-feedvalidator python-sphinx \
    && apt-get install -y default-jre \
    && apt-get upgrade -y \
    && pip3 install --upgrade pip \
    && npm install uglify-js -g \
    && npm install clean-css-cli -g \
    && rm -f /usr/bin/python && ln -s /usr/bin/python3 /usr/bin/python \
    && rm -f /usr/bin/pip && ln -s /usr/bin/pip3 /usr/bin/pip \
    && rm -rf /var/apt/lists/*

RUN gem install bundler -v $BUNDLER_VERSION \
	&& bundle config --global path "$GEM_HOME" \
	&& bundle config --global bin "$GEM_HOME/bin" \
	&& bundle config git.allow_insecure true

RUN mkdir /opendsa-lti && echo "cd /opendsa-lti" >> /root/.bashrc
WORKDIR /opendsa-lti

COPY requirements.txt requirements.txt

RUN pip3 install -r requirements.txt

COPY Gemfile Gemfile
COPY Gemfile.lock Gemfile.lock

RUN bundle install

EXPOSE 80
