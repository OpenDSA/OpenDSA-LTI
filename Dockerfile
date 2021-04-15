FROM docker.io/bitnami/ruby:2.7

MAINTAINER Jihane Najdi <jnajdi@vt.edu>

# Default environment
ARG RAILS_ENV='development'
ARG ODSA_BRANCH='master'
ARG LTI_BRANCH='master'

ENV TZ=America/New_York
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Setting the default opendsa Makefile variable ODSA_ENV to 'PROD'
ENV ODSA_ENV='PROD'

ENV GEM_HOME /usr/local/bundle
ENV PATH $GEM_HOME/bin:$PATH
ENV BUNDLER_VERSION 2.1.4

ENV RAILS_ENV=$RAILS_ENV
ENV ODSA_BRANCH=$ODSA_BRANCH
ENV LTI_BRANCH=$LTI_BRANCH

# shared-mime-info temporary due to mimemagic issues
RUN apt-get update -qq \
    && apt-get install -y apt-utils build-essential cron \
    && apt-get install -y libyaml-dev libevent-dev libxml2 libffi-dev libxslt-dev \
    && apt-get install -y shared-mime-info \
    && rm -rf /var/apt/lists/*

RUN gem install bundler -v $BUNDLER_VERSION \
	&& bundle config --global path "$GEM_HOME" \
	&& bundle config --global bin "$GEM_HOME/bin" \
	&& bundle config git.allow_insecure true

RUN mkdir /opendsa-lti && echo "cd /opendsa-lti" >> /root/.bashrc
WORKDIR /opendsa-lti

COPY Gemfile Gemfile
COPY Gemfile.lock Gemfile.lock

RUN bundle config build.nokogiri --use-system-libraries
RUN bundle check || bundle install

EXPOSE 80
