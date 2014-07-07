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

### API example

The logstream CLI --debug option shows API messages as they
occur. Here is hypothetical debug output for the Dev environment of a
site named "mysite" up to the first actual log message arriving. By
default, the CLI enables the log types apache-request, php-error,
drupal-watchdog, and varnish-request.

```
$ logstream tail devcloud:mysite dev --debug
-> connect to wss://logstream.acquia.com/ah_websocket/logstream/v1
-> {"site":"devcloud:mysite","d":"deaefc1f42a4d18cb932c2eb9fa75115fba5ab83f1a3c564767ef1ce8dabf2cc","t":1404764927,"env":"dev","cmd":"stream-environment"}
<- {"cmd":"connected","server":"logstream-api-61"}
<- {"cmd":"connected","server":"bal-4"}
<- {"type":"bal-request","cmd":"available","server":"bal-4","display_type":"Balancer request"}
<- {"type":"varnish-request","cmd":"available","server":"bal-4","display_type":"Varnish request"}
-> {"cmd":"enable","type":"varnish-request","server":"bal-4"}
<- {"server":"srv-6","cmd":"connected"}
<- {"display_type":"Apache request","server":"srv-6","cmd":"available","type":"apache-request"}
-> {"cmd":"enable","type":"apache-request","server":"srv-6"}
<- {"display_type":"Apache error","server":"srv-6","cmd":"available","type":"apache-error"}
<- {"display_type":"PHP error","server":"srv-6","cmd":"available","type":"php-error"}
-> {"cmd":"enable","type":"php-error","server":"srv-6"}
<- {"display_type":"Drupal watchdog","server":"srv-6","cmd":"available","type":"drupal-watchdog"}
-> {"cmd":"enable","type":"drupal-watchdog","server":"srv-6"}
<- {"display_type":"Drupal request","server":"srv-6","cmd":"available","type":"drupal-request"}
<- {"server":"bal-5","cmd":"connected"}
<- {"msg":{"type":"varnish-request","server":"bal-4","cmd":"enable"},"cmd":"success","server":"bal-4"}
<- {"server":"srv-6","cmd":"success","msg":{"server":"srv-6","cmd":"enable","type":"apache-request"}}
<- {"server":"srv-6","cmd":"success","msg":{"server":"srv-6","cmd":"enable","type":"php-error"}}
<- {"server":"srv-6","cmd":"success","msg":{"server":"srv-6","cmd":"enable","type":"drupal-watchdog"}}
<- {"server":"bal-5","display_type":"Balancer request","cmd":"available","type":"bal-request"}
<- {"server":"bal-5","display_type":"Varnish request","cmd":"available","type":"varnish-request"}
-> {"cmd":"enable","type":"varnish-request","server":"bal-5"}
<- {"server":"bal-5","cmd":"success","msg":{"server":"bal-5","type":"varnish-request","cmd":"enable"}}
<- {"text":"107.0.255.129 - - [07/Jul/2014:20:28:53 +0000] \"GET / HTTP/1.0\" 200 2454 \"-\" \"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_7_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/35.0.1916.153 Safari/537.36\" vhost=mysitedev.devcloud.acquia-sites.com host=mysitedev.devcloud.acquia-sites.com hosting_site=mysitedev pid=6863 request_time=80001 request_id=\"v-4fe9953a-0615-11e4-9fd8-1231392c7b9c\"","server":"srv-6","cmd":"line","http_status":200,"log_type":"apache-request","disp_time":"2014-07-07 20:28:53"}
107.0.255.129 - - [07/Jul/2014:20:28:53 +0000] "GET / HTTP/1.0" 200 2454 "-" "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_7_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/35.0.1916.153 Safari/537.36" vhost=eebjaspandev.devcloud.acquia-sites.com host=eebjaspandev.devcloud.acquia-sites.com hosting_site=eebjaspandev pid=6863 request_time=80001 request_id="v-4fe9953a-0615-11e4-9fd8-1231392c7b9c"
```

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

### list-available (inbound) and list-available (outbound)

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

