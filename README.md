# Logstream

Logstream is an Acquia service for streaming logs from Acquia Cloud. It
supports streaming a variety of log sources:

* Web (Apache) access and error logs
* PHP error log
* Acquia Cloud's Drupal Request log
* Drupal watchdog log (if the syslog.module is enabled)
* Varnish cache logs

This repository contains a client-side library and CLI. Acquia Cloud provides
<a href="https://docs.acquia.com/cloud/configure/logging/stream">a browser-based
UI</a> as well.

## Quick start

* Logstream works in conjunction with Acquia's <a
href="http://cloudapi.acquia.com/">Cloud API</a>. If you haven't already,
install your <a href="https://accounts.acquia.com/account/security">Acquia
Cloud Drush integration</a> files, which includes your Cloud API credentials.

* Install the Logstream CLI:
```
$ gem install logstream
```

* List all the sites you have access to:
```
$ drush ac-site-list
devcloud:mysite
```

* Stream logs from the production environment:
```
$ logstream tail devcloud:mysite prod
127.0.0.1 - - [11/Jun/2014:17:28:47 +0000] "GET / HTTP/1.1" 200 7708 "-" "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_7_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/35.0.1916.114 Safari/537.36" http_host=mysite.com affinity="-" upstream_addr="10.218.29.150:80" hosting_site=mysite request_time=0.030 forwarded_for="64.80.128.4" upstream_status="200"
... etc ...
```

A variety of filtering and display options are available:

```
$ logstream help tail
```

## API v1

Logstream communicates over TCP using the WebSocket protocol. Use the <a
href="http://cloudapi.acquia.com/#GET__sites__site_envs__env_logstream-instance_route">logstream
Cloud API call</a> to retrieve the URL to connect to and an authenticated
message to initial streaming for a particular Cloud environment.

Messages use text data frames, and contain JSON-encoded hashes. Each message
contains a key 'cmd' which specifies the action to perform, and defines the
other elements of the hash.

Available commands are defined in the following subsections. Inbound
commands can arrive from the upstream client (end-user client, or an
upstream logtailor). Outbound commands are sent to the upstream client.

### success (outbound)

Sent by a variety of commands when a triggering command is completed
successfully (failures result in an error command). Since some commands execute
on multiple servers, a single command may generate multiple success
replies. Parameters:

* msg: the message that succeeded

### error (outbound)

Sent when an error occurs, either because of a bad request or any kind of
system or network failure. Since some commands execute on multiple servers, a
single command may generate multiple error replies. Parameters:

* code: an HTTP-like status code; i.e.: 400 means your fault, 500 means our
  fault.
* description: a human-readable description of the error condition
* during: the operation that triggered the error

### connected (outbound)

Sent upon initial connection to a server. Parameters:

* server: the name of the connected server

### available (outbound)

Sent to indicate an available log source. Parameters:

* type: the log type (e.g. apache-access)
* display: the suggested display name for the log type (e.g. "Apache access")
* server: the originating server for this stream

### list-available (inbound) and list-availabe (outbound)

Requests a list of all available log sources from one specified server or all
servers. Parameters:

* server: the originating server to list; if not specified, all
  connected servers will reply.

One or all servers will send available messages for each available log source.

### enable (inbound)

Starts streaming a specific source previously offered via an
"available" command. Parameters:

* type: the log type to start streaming
* server: the originating server to stream from

Sends a success or error reply.

### disable (inbound)

Stops streaming from an enabled source. Parameters:

* type: the log type to stop streaming
* server: the originating server to stream from

Sends a success or error reply.

### list-enabled (inbound) and list-enabled (outbound)

Requests a list of all enabled log sources from one specified server or all
servers. Parameters:

* server: the originating server to list; if not specified, all
  connected servers will reply.

One or all servers will send a list-enabled reply. Parameters:

* enabled: an array of enabled log sources
* server: the server these logs are enabled on

### line (outbound)

Sent when a new, enabled line of log data is available. Parameters:

* type: the log type for this line (e.g. apache-access)
* server: this line's originating server name (e.g. web-1).
* unix_time: the Unix timestamp for this log line
* disp_time: the formatted display time for this log line
* text: the log text

Line messages may also contain other data depending on the log type:

* http_status: the HTTP status code, if the log line records an HTTP request
  (e.g. from Apache, nginx, Varnish, etc)

