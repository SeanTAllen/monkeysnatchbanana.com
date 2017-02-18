+++
date = "2010-08-18T08:51:50-05:00"
title = "Using FastCGI with Nginx and Seaside"
tags = ["GLASS","nginx","smalltalk","seaside"]
author = "Sean T. Allen"
slug = "using-fastcgi-with-nginx-and-seaside"
draft = false

+++

## Why FastCGI a.k.a Why Not Reverse Proxy?

I've [previously written](/2010/06/24/reverse-proxying-to-seaside-with-nginx/) about why I prefer reverse proxying to FastCGI. I still believe all those points, however there are certain Seaside deployment situations where FastCGI is currently preferable to reverse proxying. If you are deploying your Seaside application to run on Gemstone's [GLASS](http://seaside.gemstone.com/) then you should give FastCGI serious consideration. The current swazoo adapter that you use when proxying to GLASS is nowhere near as battle tested as the FastCGI adapter. If you want a rock solid deployment, FastCGI will give you much better results than Swazoo. 

## Our Bare Bones Nginx FastCGI Configuration

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
  
  upstream seaside 
  {
    server localhost:9001;
    server localhost:9002;
    server localhost:9003;
  }

  server
  {
    root /var/www/glass/;

    location /
    { 
      error_page 403 404 = @seaside;
    }
    
    location @seaside
    {
      include fastcgi_params;
      fastcgi_pass seaside;
    }
  }
}
```

The preceeding bit of code is a mostly bare bones Nginx to GLASS FastCGI configuration. There isn't a whole lot to it, so I will quickly hit the points of interest:

### Lines 13-18

```
upstream seaside 
{
  server localhost:9001;
  server localhost:9002;
  server localhost:9003;
}
```

Define a named upstream pool called _seaside_. The default GLASS installation sets up 3 FastCGI listeners on ports 9001 to 9003. You would just add more server entries in the upstream block to have Nginx start using any additional FastCGI listeners that you might setup in GLASS.

### Line 22

```
root /var/www/glass/;
```

Defines where our static assets like images, css and html are served from. You need to change the definition to a directory you create or create _/var/www/glass/_ and populate it with your various assets.

### Lines 24-27

```
location /
{ 
  error_page 403 404 = @seaside;
}
```

Define a location handler[^n] that encompasses everything that matches '/'. Any standard uri will match against this location so, you can consider it to be "global" in scope. Line 26 states that any uri request that would result in an http 403 or 404 response code should be routed to the named location _@seaside_. N.B. This named location is not the same as our upstream block. Nginx will process a request as follows:

1. Check to see if a static asset for the uri exists. If it does, return it.
2. If a static asset doesn't exist then either a 403 or 404 error will be generated resulting in handing the uri off to the @seaside location.

This could also be done as:

```
location /
{ 
  try_files $uri @seaside;
}
```

Getting into the details of why you would prefer _try\_files_ or _error\_page_ is the subject for another post.

### Lines 29-33

```
location @seaside
{
  include fastcgi_params;
  fastcgi_pass seaside;
}
```

Define our named @seaside location that is responsible for handling FastCGI. The _include fastcgi\_params_ directive has Nginx include its standard FastCGI protocol definitions that are installed at _/etc/nginx/fastcgi\_params_. The _fastcgi\_pass_ directive simply says: 'pass all uris from this to the servers defined in the _seaside_ upstream block'.

## Are We Done?

Yes. Yes we are. There is plenty more configuration that can be added to make the FastCGI handling more robust ( failovers, timeouts etc ), but that is all you need to get started. I would suggest visiting the [Nginx wiki](http://wiki.nginx.org/) to learn about Nginx so you can flesh out your configuration. If you run into issues or need any help, feel free to drop me an email or catch up with me on [Twitter](http://www.twitter.com/SeanTAllen).

<div class="footnotes"><ol><li class="footnote" id="fn:1"><p>See the <a href="http://wiki.nginx.org/NginxHttpCoreModule#location">Nginx wiki</a> for more information on the location directive. <a href="#fnref:1" title="return to article">↩</a></p></li></ol></div>
