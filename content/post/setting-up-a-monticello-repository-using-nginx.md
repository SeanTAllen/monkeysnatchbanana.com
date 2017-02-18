+++
slug = "setting-up-a-monticello-repository-using-nginx"
date = "2010-10-05T08:46:14-05:00"
title = "Setting up a Monticello repository using Nginx"
draft = false
tags = ["nginx","smalltalk"]
author = "Sean T. Allen"

+++
## How Hard Could It Be?

Not very hard; this little monkey who is more interested in bananas did it in no time flat. Setting up and running your own private Monticello repository is something almost any Smalltalker should be able to accomplish; as long as your aren't completely command line and systems administration phobic, you should be done with my directions within half an hour.

## Installing Nginx with WebDAV Support

Most prepackaged binary version of Nginx don't support WebDAV. If this is the case with yours, [download the latest stable version](http://nginx.org/) and build following the included instructions. You will need to change the standard configure step to one of the following:

### Basic configuration

```
./configure --with-http_dav_module
```

### Advanced configuration to match the standard Debian/Ubuntu packages

```
./configure --prefix=/var/lib/nginx --conf-path=/etc/nginx/nginx.conf \ 
  --pid-path=/var/run/nginx.pid --error-log-path=/var/log/nginx/error.log \
  --http-log-path=/var/log/nginx/access.log --lock-path=/var/run/nginx.lock \
  --user=www-data --group=www-data --sbin-path=/usr/sbin/nginx --with-http_dav_module
```

## Our Bare Bones Nginx Monticello Server Configuration

```
01: worker_processes 1;
02: 
03: events
04: {
05:   worker_connections  1024;
06: }
07: 
08: http
09: {
10:   include       mime.types;
11:   default_type  application/octet-stream;
12:   
13:   server
14:   {
15:     listen monticello.example.com;
16:     server_name monticello.example.com;
17: 
18:     location / 
19:     {
20:       auth_basic "Monticello access restricted";
21:       auth_basic_user_file /PATH_TO_OUR_PASSWORD_FILE;
22: 
23:       autoindex on;
24: 
25:       root /PATH_TO_OUR_MONTICELLO_REPOSITORY;
26: 
27:       dav_methods          PUT;
28:       create_full_put_path on;
29:       dav_access           group:rw  all:r;
30:     } 
31:   }
32: }
```

The preceeding bit of code is a mostly bare bones Nginx Monticello server configuration. There isn't a whole lot to it, so I will quickly hit the points of interest:

### Lines 15-16

```
listen monticello.example.com;
server_name monticello.example.com;
```

Setup the name of our Monticello server and address it should be listening on.

### Lines 18-19 & 30

```
location /
{
}
```

Define a location handler[^n] that encompasses everything that matches '/'. Any standard uri will match against this location so, you can consider it to be "global" in scope. Everything we want our Monticello server to do is handled by this one location handler.

### Lines 20-21

```
auth_basic "Monticello access restricted";
auth_basic_user_file /PATH_TO_OUR_PASSWORD_FILE;
```

Protects our Monticello repository from anonymous access using HTTP Basic Authentication. */PATH_TO_OUR_PASSWORD_FILE* should be replaced with the location of your password file. Your password file can be generated either using Apache's htpasswd application or using [this python script](http://wiki.nginx.org/NginxFaq#How_do_I_generate_an_httpasswd_file_without_having_Apache_tools_installed). N.B. Your password file has to be readable by the user that Nginx is running as. When installing from source, the default Nginx user is 'nobody'; the default in Debian Linux is 'www-data'.

### Line 23

```
autoindex on;
```

Is required for WebDAV to function properly- without directory indexing on, you will run into access denied errors.

### Line 25

```
root /PATH_TO_OUR_MONTICELLO_REPOSITORY;
```

Defines the root of our WebDAV server. */PATH_TO_OUR_MONTICELLO_REPOSITORY* should be replaced with the directory that you are storing Monticello packages in. The directory has to be readable and writable by the user that Nginx is running as.

### Lines 27-29

```
dav_methods          PUT;
create_full_put_path on;
dav_access           group:rw  all:r;
```

Define the rest of our WebDAV server setup. Instead of rehashing the [Nginx WebDAV documentation](http://wiki.nginx.org/HttpDavModule) I suggest you check the preceeding link as it covers this section of our setup in about as much time as it would take for me to detail it.

## Are We Done?

Indeed, but there is plenty more configuration that can be added to this basic Nginx WebDAV/Monticello setup. I would suggest visiting the [Nginx wiki](http://wiki.nginx.org/) to learn about Nginx so you can flesh out your configuration.

<div class="footnotes"><ol><li class="footnote" id="fn:1"><p>See the <a href="http://wiki.nginx.org/NginxHttpCoreModule#location">Nginx wiki</a> for more information on the location directive. <a href="#fnref:1" title="return to article">↩</a></p></li></ol></div>
