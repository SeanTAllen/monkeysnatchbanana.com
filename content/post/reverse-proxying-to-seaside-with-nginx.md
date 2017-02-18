+++
author = "Sean T. Allen"
slug = "reverse-proxying-to-seaside-with-nginx"
draft = false
date = "2010-06-24T08:56:43-05:00"
title = "Reverse Proxying to Seaside with Nginx"
tags = ["nginx","smalltalk","seaside"]

+++

## Why Reverse Proxy a.k.a Why Not FastCGI?

Transparency.

FastCGI setups are opaque. You can't easily test all aspects of it. Unless you write your own FastCGI client, debugging configuration problems can be very difficult. Lets imagine for a moment that are trying to debug a problem with your application-- the issue might be in the front end server or it might be in the Seaside application server. When you are using FastCGI, all your interactions with your application server are routed through the front end server which acts as a client for you. If you are reverse proxying to your Seaside application running at `http://127.0.0.1:8080/`, you can fire up lynx[^n] and hit the application directly. No error from the application? Probably a front end server issue. It might be slightly hyperbolic, but I can't count the number of hours of head scratching this has saved me.

## Reverse Proxying to Seaside Options

Now that you have decided that you want to use reverse proxying to your Seaside application, you need to decide between a couple of basic setup options. You can either setup each application on its own subdomain of your domain or you can run multiple applications off the same domain.

### One Application Per Subdomain

Our first example, shows a basic setup for running the counter and multicounter example applications off their own subdomains. With this configuration, you would be able to access the counter example via the uri `http://counter.example.com/` and the multicounter example via `http://multicounter.example.com/`.

```
01: server
02: {
03:   server_name counter.example.com;
04:  
05:   rewrite ^/$ /examples/counter;
06:   proxy_redirect /examples/counter /;
07:
08:   location /examples/counter
09:   {
10:     proxy_pass http://127.0.0.1:8080;
11:   }
12: }
13:
14: server
15: {
16:   server_name multicounter.example.com;
17:  
18:   proxy_redirect /examples/multicounter /;
19:   rewrite ^/$ /examples/multicounter;
20:
21:   location /examples/multicounter
22:   {
23:     proxy_pass http://127.0.0.1:8080;
24:   }
25: }
```

If you've never seen a nginx configuration file before that might be quite a bit to absorb, so lets break it down: 

* We setup two virtual servers, one for each application. This is done via the server {} directives that start on lines 1 and 14. Each virtual server is almost identical except counter appears in one and multicounter in the other.
* Line 3 tells our first server to respond to requests for the host `counter.example.com`.
* Line 5 rewrites `http://counter.example.com/` to `http://counter.example.com/examples/counter`. _This change in URI isn't seen by the client browser_.
* Line 6 removes `/examples/counter` from URIs being returned by the counter application.
* Line 8 sets up an nginx location. It passes the URI `/examples/counter` to a our application server listening on port 8080 of localhost.

### Multiple Applications Per Domain 

For our multiple applications per domain example, we are going to setup example.com to server any of the example Seaside applications. All the example Seaside applications start with their URI path with `/examples`-- a nicety we will take advantage of.

```
1: server
2: {
3:   server_name example.com;
4:
5:   location /examples
6:   {
7:     proxy_pass http://127.0.0.1:8080/examples;
8:   }
9: }
```

The nginx location we setup on line 5, routes anything under `/examples` to the same path on our application server. Under this setup, we could access the counter application at `http://example.com/examples/counter` and multi counter application at `http://example.com/examples/multicounter`.

## Complete Nginx Reverse Proxy Server Configuration[^n]

Building on the 'One Application Per Subdomain' setup above, lets setup the serving a hypothetical To Do application. Our application will be responsible for serving the site's homepage. Nginx will serve any static assets ( css files, images etc ).

```
01: server
02: {
03:   server_name todo.example.com;
04:  
05:   root /var/www/todo.example.com/;
06:   
07:   location /
08:   {
09:     try_files $uri $uri/;
10:   }
11:   
12:   proxy_redirect /todo /;
13:   rewrite ^/$ /todo;
14: 
15:   location /todo
16:   {
17:     proxy_pass http://127.0.0.1:8080;
18:   }
19: }
```

A quick breakdown of the new elements we've introduced:

* Line 5 tells nginx that any static attributes should be located by looking in `/var/www/todo.example.com/` This is equivalent to Apache's DocumentRoot directive.
* The location directive that starts on line 7 defines how nginx should locate static assets[^n]. The try\_files directive on line 9 tells nginx to try to means to satisfy a URI. If our incoming request has a path of `/about` then, nginx will first look for a file called `about` in the server root. If that isn't found nginx will look for a directory `about/` in the server root. If neither rule can be satisfied, nginx will return a 404 error. 
* Line 15 defines a location rule that is more specific than the one on line 7.  It will only be triggered if the URI path is `/todo`. This is the same setup that we saw in both of our previous examples.

## Putting It All Together

Now all we have to do is drop our reverse proxy server configuration into our nginx configuration and we end up with something like[^n]...

```
worker_processes 1;

events
{
  worker_connections  1024;
}

http
{
  include       mime.types;
  default_type  application/octet-stream;
      
  server
  {
    server_name todo.example.com;
 
    root /var/www/todo.example.com/;
  
    location /
    {
      try_files $uri $uri/;
    }
  
    proxy_redirect /todo /;
    rewrite ^/$ /todo;

    location /todo
    {
      proxy_pass http://127.0.0.1:8080;
    }
  }
}
```

<div class="footnotes"><ol><li class="footnote" id="fn:1"><p>Or any other http client; one of my favorites is <a href="http://github.com/cloudhead/http-console">http console</a>. <a href="#fnref:1" title="return to article">↩</a></p></li>

<li class="footnote" id="fn:2"><p>See <a href="http://wiki.nginx.org/NginxHttpProxyModule">Nginx wiki</a> for complete Nginx proxy module documentation. If you are running multiple Seaside application instances (on GLASS for instance), you should also check out the <a href="http://wiki.nginx.org/NginxHttpUpstreamModule">upstream</a>, <a href="http://wiki.nginx.org/NginxHttpUpstreamFairModule">fair upstream</a> and <a href="http://wiki.nginx.org/NginxHttpUpstreamRequestHashModule">upstream request hash</a> modules. <a href="#fnref:2" title="return to article">↩</a></p></li>

<li class="footnote" id="fn:3"><p>Location / is the most general location rule possible with nginx. It will used if a more specific location can't be found. <a href="#fnref:3" title="return to article">↩</a></p></li>

<li class="footnote" id="fn:4"><p>Yours may look radically different. This is just a basic example of a full nginx configuration file. <a href="#fnref:4" title="return to article">↩</a></p></li></ol></div>
