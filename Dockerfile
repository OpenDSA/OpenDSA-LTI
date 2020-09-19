FROM ruby:2.7.1

MAINTAINER Jihane Najdi <jnajdi@vt.edu>

#Default environment
ARG RAILS_ENV='development'

ENV TZ=America/New_York
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN apt-get update -qq \
    && apt-get install -y apt-utils build-essential libpq-dev lsof vim cron curl \
    && apt-get install -y nodejs npm python3-pip git-core zlib1g-dev libssl-dev libreadline-dev libyaml-dev  libevent-dev libsqlite3-dev libsqlite3-dev     libxml2-dev   libxml2  libxslt1-dev   libffi-dev    libxslt-dev   sqlite3   dkms  python-dev python-feedvalidator     python-sphinx   python3-venv \
    && apt-get install -y default-jre \
    && apt-get upgrade -y \
    && pip3 install --upgrade pip \
    && npm install npm@latest -g  \
    && npm install uglify-js -g \
    && npm install clean-css-cli -g

# Set default python version to python 3
RUN rm -f /usr/bin/python && ln -s /usr/bin/python3 /usr/bin/python
RUN rm -f /usr/bin/pip && ln -s /usr/bin/pip3 /usr/bin/pip

# Clone OpenDSA
RUN mkdir /opendsa
RUN git clone https://github.com/OpenDSA/OpenDSA.git /opendsa

RUN ln -s "$(which nodejs)" /usr/local/bin/node

##Setting the default opendsa Makefile variable ODSA_ENV to 'PROD' and PYTHON to 'python'
ENV PYTHON='python'
ENV ODSA_ENV='PROD'

# install rubygems
ENV GEM_HOME /usr/local/bundle
ENV PATH $GEM_HOME/bin:$PATH
ENV BUNDLER_VERSION 2.1.4

ENV RAILS_ENV=$RAILS_ENV

RUN gem install bundler -v $BUNDLER_VERSION \
	&& bundle config --global path "$GEM_HOME" \
	&& bundle config --global bin "$GEM_HOME/bin" \
	&& bundle config git.allow_insecure true

RUN mkdir /opendsa-lti
WORKDIR /opendsa-lti

COPY Gemfile Gemfile
COPY Gemfile.lock Gemfile.lock

RUN bundle install

EXPOSE 80

# CMD ["./scripts/start.sh"]
