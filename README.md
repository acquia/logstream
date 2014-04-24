# Logstream

Logstream is an Acquia service for streaming logs from Acquia Cloud.

It is currently in internal-only alpha release. There is a rough CLI and no
web UI.

## Quick start

```
ruby logstream.rb tail <site> <env>
```

A variety of filtering and display options are available:

```
ruby logstream.rb help tail
```

## Details

It supports streaming these log sources for all relevant servers for all sites
on Acquia Cloud:

* Web (Apache) access and error logs
* PHP error log
* Acquia Cloud's Drupal Request log
* Drupal watchdog log (if the syslog.module is enabled)
* Varnish cache logs
* Load balancer (nginx) access logs

Logstream is implemented using https://github.com/acquia/logtailor.

Logstream will be in public beta when a web-based UI is available. For now,
this repo contains a CLI tool. A variety of Ruby gems are required; a Gemfile
listing them all is forthcoming. PRs welcome. :-)

Logstream authentication is based on Cloud API. A Logstream client uses a <a
href="http://cloudapi.acquia.com/#GET__sites__site_envs__env_logstream-instance_route">logstream
API call</a> to retrieve an authenticated message to send to
wss://logstream.acquia.com, which initiates streaming. This means that anyone
with access to a site on Cloud API can stream its logs via Logstream.


