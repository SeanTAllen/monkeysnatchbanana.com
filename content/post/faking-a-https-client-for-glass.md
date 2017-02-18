+++
date = "2010-06-22T08:59:50-05:00"
title = "Faking a https client for GLASS"
slug = "faking-a-https-client-for-glass"
draft = false
tags = ["GLASS","nginx","smalltalk","seaside"]
author = "Sean T. Allen"

+++

So, you are humming along developing your GLASS hosted Seaside application. If you are following the proscribed development path, your application is running in Pharo and you've started porting it to GLASS when a problem arises:

Your application needs to make calls out to a secure web service (merchant processor etc) but, GLASS doesn't have a native https client. The Pharo [cryptography package](http://www.squeaksource.com/Cryptography.html) implements an https client which you could port to Gemstone, but the process model it uses doesn't map nicely and you have better things to do with your time. You could wrap up the [C OpenSSL library](http://www.openssl.org/) and access it from Smalltalk-- also a large amount of work or... you could go for the quick, dirty and effective approach: open a regular http connection and run it through a https proxy. This article covers the last option.

## Http to Https Proxying

A [proxy server](http://en.wikipedia.org/wiki/Proxy_server) is *a server (a computer system or an application program) that acts as an intermediary for requests from clients seeking resources from other servers.* In our current scenario, our Seaside application will make an http connection to a local proxy that will in turn open a https connection to a remote server passing our info along in the process. In order to accomplish this, we will give a hostname to our proxy and connect to it from our smalltalk code. Lets say you want to use a resource on the server *api.secure_service.com*, you need to setup a name for the proxy that does the actual connection to *api.secure_service.com*. If proxy is running on your local machine and you want to name it *secure_service*, add the following entry to your machine's */etc/hosts* file[^n]:

```
127.0.0.1   secure_service
```

From our smalltalk code instead of opening a connection to *https://api.secure_service.com/apiLocation*, we will open a connection to *http://secure_service/apiLocation*. With this simple code change out of the way, we can move on to setting up the proxy. There are two primary options for doing http to https proxying. Using [stunnel](http://stunnel.mirt.net/) or a proxying web server:

### Stunnel

I'm not going to give an in depth coverage to setting up stunnel as a means of doing outgoing https connections from  GLASS. Why? For any production GLASS system, we are probably going to be running a web server in front of the swazoo, hyper or fastcgi adapter that is serving your Seaside content; that web server is all you need. If we use stunnel to as a proxy for our http to https connections, we are just adding another point of failure to our setup. By using our existing web server as the proxy, there is less to worry about. If our web server goes down, we aren't going to need the https proxying as we have bigger problems.

### Proxying Web Server

We could use [apache](http://httpd.apache.org/docs/2.0/mod/mod_proxy.html), [lighttpd](http://redmine.lighttpd.net/wiki/lighttpd/Docs:ModProxy) or any other proxying web server to implement the following solution. I'll use [Nginx](http://www.nginx.org)[^n] as it is the server I'm most comfortable with. We already added a name for our */etc/hosts* and now it is time to add an additional server entry to our *nginx.conf* file[^n].

```
server
{
  server_name secure_service;
  
  location /
  {
    proxy_pass https://api.secure_service.com;
  }
}
```

Restart Nginx and we are good to go.

## Using test resources

If we use a build system and the remote service offers production and testing versions, we can get an added bonus from the proxy setup: easy switching at build time between production and testing services.

Let's assume that *secure_service* is a merchant processing provider that provides a test interface where no billing is actually done as well as a production system where transactions are charged to the consumer. Instead of having testing and production objects that change the url we are using, we can have a build system insert the correct url in our *nginx.conf file*. If we are using a [standard c preprocessor](http://gcc.gnu.org/onlinedocs/cpp/index.html)[^n], the following setup and slight *nginx.conf* change allows us to switch from production to testing at build time rather than relying on switching objects in our smalltalk code:

```
#ifdef PRODUCTION
#define SECURE_SERVICE_URL  production-api.secure_service.com
#else
#define SECURE_SERVICE_URL  testing-api.secure_service.com
#endif
```

```
server
{
  server_name secure_service;
  
  location /
  {
    proxy_pass https://SECURE_SERVICE_URL;
  }
}
```

[^n]: If we need to access your proxy from multiple machines, using real dns entries for our domain will make maintenance much easier.

[^n]: You need to configure Nginx at build time to include https support.

[^n]: Normally located in /etc/nginx.conf

[^n]: Any preprocessor would do.
