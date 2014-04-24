# Logstream

Logstream is an Acquia service for streaming logs from Acquia Cloud.

Logstream is currently in internal-only alpha release. An initial CLI is
available, but no web UI. It will enter public beta when a web-based UI is
available.

This repo will eventually become public.

## Quick start

(The gem build step will be unnecessary once this becomes public because we
will host the built gem at rubygems.org.)

```
gem build logstream.gemspec
gem install logstream-*.gem
logstream tail <site> <env>
```

\<site\> is the site name according to Cloud API, which means it is prefixed
with a realm, e.g. "prod:jaspan" or "devcloud:foobar".

A variety of filtering and display options are available:

```
logstream help tail
```

## Details

Logstream supports streaming a variety of log sources from all relevant servers
for all sites on Acquia Cloud:

* Web (Apache) access and error logs
* PHP error log
* Acquia Cloud's Drupal Request log
* Drupal watchdog log (if the syslog.module is enabled)
* Varnish cache logs
* Load balancer (nginx) access logs

Logstream is websocket application. A Logstream client uses a <a
href="http://cloudapi.acquia.com/#GET__sites__site_envs__env_logstream-instance_route">logstream
Cloud API call</a> to retrieve an authenticated message to initial streaming
for a particular Cloud environment, which it sends to
wss://logstream.acquia.com to initiates log streaming. Thus, access to a site
on Cloud API also grants the ability to stream that site's logs.


