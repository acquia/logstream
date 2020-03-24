FROM ubuntu:latest

RUN apt-get update \
  && apt-get install -y \
      curl \
      make \
      build-essential \
      g++ \
      libssl-dev \
      ruby-dev \

  && mkdir /src

COPY . /src

RUN cd /src \
  && gem build logstream \
  && gem install logstream-*.gem

VOLUME ["/src"]

ENTRYPOINT ["/usr/local/bin/logstream"]
