+++
date = "2013-05-03T13:21:47-05:00"
title = "Varnish in Five Acts"
draft = false
tags = ["varnish","scaling"]
author = "Sean T. Allen"
slug = "varnish-in-five-acts"

+++


> “Take a load off Annie. Take a load for free. Take a load off Annie. And you put the load right on me.” -- Robbie Robertson

## Act I: The Players

At my current employer, we have a number of entity services that clients access via HTTP. Some examples are the job service, the job application service and the topic of this post: the job seeker service. Each service manages the lifecycle of a core entity in our domain. On each request, the service gathers data from multiple data sources to build a complete entity and then serializes that entity to JSON. This is done for every request and is incredibly wasteful when you consider that most of these entities don’t change that often. This was a major bottleneck in our infrastructure. In the case of the job seeker service, the same entity can be requested multiple times per request from our consumer website.

All this repeated, unnecessary entity object assembly and JSON serialization created scaling problems. Making matters worse, we periodically have batch processes that can increase service load by an order of magnitude. Caching is an easy win here. The question is how.

Initial attempts to cache these entities were done inside the service JVMs, using familiar and popular JVM based caches like EHcache and calls out to memcache. Unfortunately, this left us operating at JVM speeds and the caches were competing with the service logic for memory and threads.

In addition, our service code was muddled with messy caching logic.  Making the code harder to reuse, and more annoyingly, changes just affecting caching forced us to re-release the entire service.  We didn’t like this mixing of concerns.

We thought we could do better if we used external read through caches. It's easy to slide them between existing clients and services. With caching outside the service, it get released only when their logic changes not because we’re tuning caching.

For reasons too numerous to cover in this post we chose [Varnish](https://www.varnish-cache.org/about) as our read through cache.

****

## Act II: The Architecture

When we introduced Varnish to our architecture, we wanted to make sure we were not adding a single point of failure. Simply put, if the cache layer goes down, our infrastructure should continue running. Performance might be degraded, but we should continue to be able to serve content to clients.

The diagram below shows a typical setup. In a normal scenario, a client accesses Varnish via a load balancer. Varnish in turn farms out the work in round robin fashion to one of four job seeker service nodes. Should Varnish become unavailable, the load balancer stops sending traffic to Varnish and reroutes it to the four job seeker service nodes.

![](/img/post/varnish-in-five-acts/varnish-flow.png)

Of all our entity services, the job seeker services carries the highest median load. The graph below is the 1 minute request rate on 4 service nodes over the 36 hour period before and after Varnish was turned on.

![](/img/post/varnish-in-five-acts/before-after.png)

****

## Act III: Cache Invalidation

Cache invalidation is one of the 2 hard problems in computer science along with naming things and off by one errors.

We cache job seeker entity representations until some point in the “far future”, which is great until something about that job seeker changes, then we must invalidate the cached entry. So, how do we do that?

Two ways.

### Via Header:

All requests that change the state of a job seeker that are made via the service attach a header in the response called "x-invalidates" that looks something like:

```
x-invalidates: /jobseeker/123
```

Varnish, when it sees this header, turns the value into a content expiring regular expression. My team mate [@johnconnolly](http://twitter.com/johnconnolly) learned about this general technique from [Kevin Burns Jr.](https://twitter.com/kevburnsjr) at [http://restfest.org](RESTFest) 2012.  I used Kevin’s post on the [subject](http://blog.kevburnsjr.com/tagged-cache-invalidation) as a jumping off point for our implementation.

### Via Magic:

Once upon a time, we had a database administrator named Gennady. Gennady wrote a [PHP script that reads MySQL’s binary logs](http://www.dinodigusa.com/images/Magic1.gif), looking for changes to a set of predefined tables. When it sees an update, it finds the primary key for the row and fires off an invalidation request. In our case, a purge of the cached entity url in Varnish. This allows us to invalidate cached job seeker entities even when the update was performed via legacy code that interacts directly with the database rather than through the service.

If you were to do this manually, it would look something like:

```
curl -X PURGE varnish-jobseeker/jobseeker/123
```

****

## Act IV: Configuration Spelunking

So, how did we do it? I’m going to break down our configuration into its parts and cover the general role each part plays. From here on out, I’m assuming you understand the basics of how Varnish works and how you configure it. Also, there is some repetition in our configuration that isn’t required, it just makes it easier for our configuration management tool, puppet, to create the final output.

### Load Balancing

We have four service servers behind varnish so we create four backend entries and then set up a director to round robin between them. Then in vcl_recv, we set our director named 'nodes' to be the backend that we will use to fetch content.

``` bash
backend JS1 {
  .host  = "JS1";
  .port  = "8080";

  ...
}

backend JS2 {
  .host  = "JS2";
  .port  = "8080";

  ...
}

backend JS3 {
  .host  = "JS3";
  .port  = "8080";

  ...
}

backend JS4 {
  .host  = "JS4";
  .port  = "8080";

  ...
}

director nodes round-robin {
  { .backend = JS1 ; }
  { .backend = JS2 ; }
  { .backend = JS3 ; }
  { .backend = JS4 ; }
}

sub vcl_recv {
  set req.backend = nodes;
}

# store in cache only by url, not backend host
sub vcl_hash {
  hash_data(req.url);
  return (hash);
}
```

### Degraded

Each backend is setup with a probe url that we use to check its health. If the probe url doesn't return at least one HTTP 200 response within a fifteen second period, we mark that backend as unhealthy.

``` bash
backend ... {
   ...

  .probe = {
    .url = "/donjohnson/pulse";
    .interval = 5s;
    .timeout = 250ms;
    .window = 3;
    .threshold = 2;
  }
}
```

Varnish has the concept of a grace period, wherein, we can keep content alive in our cache past the TTL based on the health status of our backends. In our case, when the all backends are down, we keep cached items alive for an extra hour. During this time, we operate in a degraded status. Read requests for cached items will be handled while write requests will fail because there is no backend service to handle them.

``` bash
sub vcl_fetch {
  # max time to keep an item in the cache past its ttl
  # used in conjunction with code in vcl_recv to
  # deal with 'sick' backends
  set beresp.grace = 1h;

  ...
}

sub vcl_recv {
  ...

  # extra ttl for cached objects based on backend health
  if (!req.backend.healthy) {
    set req.grace = 1h;
  } else {
    set req.grace = 15s;
  }
}
```

### Invalidation

We do two types of invalidation:

* invalidation based on the 'x-invalidates' header that comes back with a response
* 'manual' invalidation based on sending the HTTP PURGE verb to a url in the Varnish cache.

The ability to do a manual purge is limited to a small set of IP addresses that we validate against when a purge request is received.

``` bash
acl purge {
  "localhost";
  "10.10.10.10";
}

sub vcl_recv {
  ...

  # 'manual' purge
  if (req.request == "PURGE") {
    if (client.ip ~ purge) {
       return(lookup);
    }

    error 405 "Not allowed.";
  }

  ...
}
```

The actual mechanics of doing the purge are fairly simple. If the url attempted to be purged exists, purge it and return a 200.

``` bash
sub vcl_hit {
  # 'manual' purge
  if (req.request == "PURGE") {
    purge;
    error 200 "Purged.";
  }
}
```

If it doesn't, return a 404 response code:

``` bash
sub vcl_miss {
  # 'manual' purge
  if (req.request == "PURGE") {
    purge;
    error 404 "Not in cache.";
  }
}
```

Update requests include invalidation-related headers. Every request we fetch has, inside of Varnish, its request url stored in a special x-url header. This will be used as the url to check the x-invalidates header against. As this header is purely for our internal use, we remove it before delivering items to a client:

``` bash
sub vcl_fetch {
  ...

  set beresp.http.x-url = req.url;

  ...
}

sub vcl_deliver {
  # clear internal cache invalidation header before sending to client
  unset resp.http.x-url;
}
```

Any 'successful' PUT, POST, DELETE or PATCH response will have its x-invalidates header used as a regular expression to invalidate existing content whose x-url header matches the x-invalidates regex.

```
sub vcl_fetch {
  ...

  # cache invalidation
  set beresp.http.x-url = req.url;
  if (req.request == "PUT" || req.request == "POST" || req.request == "DELETE" || req.request == "PATCH") {
    if  (beresp.status >= 200 && beresp.status < 400) {
     ban("obj.http.x-url ~ " + beresp.http.x-invalidates);
    }
  }
}
```
****

## Act V: The final product

And finally, we put it all together into a complete file (note, we use Varnish 3, the semantics around ban/purge changed from v2 to v3):

``` bash
backend JS1 {
  .host  = "JS1";
  .port  = "8080";
  .probe = {
    .url = "/donjohnson/pulse";
    .interval = 5s;
    .timeout = 250ms;
    .window = 3;
    .threshold = 2;
  }
}

backend JS2 {
  .host  = "JS2";
  .port  = "8080";
  .probe = {
    .url = "/donjohnson/pulse";
    .interval = 5s;
    .timeout = 250ms;
    .window = 3;
    .threshold = 2;
  }
}

backend JS3 {
  .host  = "JS3";
  .port  = "8080";
  .probe = {
    .url = "/donjohnson/pulse";
    .interval = 5s;
    .timeout = 250ms;
    .window = 3;
    .threshold = 2;
  }
}

backend JS4 {
  .host  = "JS4";
  .port  = "8080";
  .probe = {
    .url = "/donjohnson/pulse";
    .interval = 5s;
    .timeout = 250ms;
    .window = 3;
    .threshold = 2;
  }
}

director nodes round-robin {
  { .backend = JS1 ; }
  { .backend = JS2 ; }
  { .backend = JS3 ; }
  { .backend = JS4 ; }
}

# what machines can institute a 'manual' purge
acl purge {
  "localhost";
  "192.1.1.4";
}

# store in cache only by url, not backend host
sub vcl_hash {
  hash_data(req.url);
  return (hash);
}

sub vcl_fetch {
  # max time to keep an item in the cache past its ttl
  # used in conjunction with code in vcl_recv to
  # deal with 'sick' backends
  set beresp.grace = 1h;

  # cache invalidation
  set beresp.http.x-url = req.url;
  if (req.request == "PUT" || req.request == "POST" || req.request == "DELETE" || req.request == "PATCH") {
    if  (beresp.status >= 200 && beresp.status < 400) {
     ban("obj.http.x-url ~ " + beresp.http.x-invalidates);
    }
  }
}

sub vcl_recv {
  set req.backend = nodes;

  # 'manual' purge
  if (req.request == "PURGE") {
    if (client.ip ~ purge) {
       return(lookup);
    }

    error 405 "Not allowed.";
  }

  # extra ttl for cached objects based on backend health
  if (!req.backend.healthy) {
    set req.grace = 1h;
  } else {
    set req.grace = 15s;
  }
}

sub vcl_deliver {
  # clear internal cache invalidation header before sending to client
  unset resp.http.x-url;
}

sub vcl_hit {
  # 'manual' purge
  if (req.request == "PURGE") {
    purge;
    error 200 "Purged.";
  }
}

sub vcl_miss {
  # 'manual' purge
  if (req.request == "PURGE") {
    purge;
    error 404 "Not in cache.";
  }
}
```

## Hidden Track Bonus Act:

![](/img/post/varnish-in-five-acts/varnish-all-the-things.jpg)

Join the discussion over at [Hacker News](https://news.ycombinator.com/item?id=5651874).
