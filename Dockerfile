FROM ubuntu:latest

RUN apt-get update \
  && apt-get install -y \
      curl \
      make \
      build-essential \
      g++ \
      libssl-dev \
      ruby-dev
RUN mkdir /src

COPY . /src

RUN cd /src \
  && gem build logstream \
  && gem install logstream-*.gem

ENTRYPOINT ["/bin/bash"]