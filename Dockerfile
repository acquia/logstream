FROM ubuntu:14.04

# APT.
RUN apt-get update
RUN apt-get install -y software-properties-common python-software-properties curl make build-essential g++
RUN add-apt-repository ppa:brightbox/ruby-ng
RUN apt-get update

# Ruby.
RUN apt-get install -y libssl-dev ruby2.1 ruby2.1-dev

# Logstream.
RUN gem install logstream

ENTRYPOINT ["logstream"]
