+++
draft = false
tags = ["pony"]
date = "2015-12-19T10:52:43-05:00"
title = "Inside the Pony TCP Stack"
author = "Sean T. Allen"
slug = "inside-the-pony-tcp-stack"

+++

In this post, we are going to take a look at how [Pony](http://www.ponylang.org/) implements its TCP stack. The API for Pony's networking stack is callback and event driven. I've previously written about [network programming in Pony](http://www.monkeysnatchbanana.com/2015/12/13/deconstructing-a-pony-echo-server/) and showed how to implement a simple echo server. We didn't, however, dive too deeply into the Pony TCP stack. In this post, we'll move down a level of abstraction and see how Pony implements classes that handle TCP socket programming in an actor friendly, event-driven fashion. This post will:

* Review the two interfaces that we previously used to implement an echo server
* Give a quick overview of how server side TCP programming works
* Recap the important TCP related bits from our echo server
* Show how Pony's [standard library networking code](https://github.com/ponylang/ponyc/tree/master/packages/net) implements standard TCP programming patterns
* Give a quick overview of Pony's [C FFI](http://tutorial.ponylang.org/c-ffi/calling-c/)
* Touch briefly on Pony's internal event system

This post features a lot of Pony code as well as a lot of C code. In order to follow along, you'll need to have some familiarity with each. If you are unfamiliar with Pony, I suggest you do a review of Pony's basic semantics by reviewing the [Pony Tutorial](http://tutorial.ponylang.org). Most of the code examples are simplified versions of actual Pony code. Where possible, I have removed platform specific code as well as code that - while important to overall functionality - has little to do with what I'm trying to teach.

Let's get started...

## A Skeleton for a Pony TCP server

<img src="https://videos.hasbro.com/img/694893024001/201502/1058/694893024001_4070167773001_MLP-MV-ThePerfectStallion-SingAlong-FINAL-720H264-vs.jpg?pubId=694893024001" align="center">

Our echo server is built around a two classes that implement interfaces that are part of the Pony network stack. Each method in the interfaces corresponds to an event that can happen while interacting with or attempting to interact with a network resource. The particulars aren't that important right now, what is important is recognizing the callback driven nature of network programming with Pony. Pony handles the details of networking programming while users of the API are responsible for providing code that runs at certain key points. Here's the interface for _listeners_. As you will see when we cover TCP/IP server basics soon, the methods in the _TCPListenNotify_ interface map to events that can occur in server applications that are responsible for dispatching incoming requests.

```
interface TCPListenNotify
  """
  Notifications for TCP listeners.
  """
  fun ref listening(listen: TCPListener ref) =>
    """
    Called when the listener has been bound to an address.
    """
    None

  fun ref not_listening(listen: TCPListener ref) =>
    """
    Called if it wasn't possible to bind the listener to an address.
    """
    None

  fun ref closed(listen: TCPListener ref) =>
    """
    Called when the listener is closed.
    """
    None

  fun ref connected(listen: TCPListener ref): TCPConnectionNotify iso^ ?
    """
    Create a new TCPConnectionNotify to attach to a new TCPConnection for a
    newly established connection to the server.
    """
```

As you might notice in the _TCPListenNotify_ code above, the return type for the ```connected``` method is a ```TCPConnectionNotify``` instance. ```TCPConnectionNotify``` is our second interface that we need to implement. 

```
interface TCPConnectionNotify
  """
  Notifications for TCP connections.
  """
  fun ref accepted(conn: TCPConnection ref) =>
    """
    Called when a TCPConnection is accepted by a TCPListener.
    """
    None

  fun ref connecting(conn: TCPConnection ref, count: U32) =>
    """
    Called if name resolution succeeded for a TCPConnection and we are now waiting for a connection to the server to succeed. The count is the number of connections we're trying. The notifier will be informed each time the count changes, until a connection is made or connect_failed() is called.
    """
    None

  fun ref connected(conn: TCPConnection ref) =>
    """
    Called when we have successfully connected to the server.
    """
    None

  fun ref connect_failed(conn: TCPConnection ref) =>
    """
    Called when we have failed to connect to all possible addresses for the server. At this point, the connection will never be established.
    """
    None

  fun ref auth_failed(conn: TCPConnection ref) =>
    """
    A raw TCPConnection has no authentication mechanism. However, when protocols are wrapped in other protocols, this can be used to report an authentication failure in a lower level protocol (eg. SSL).
    """
    None

  fun ref sent(conn: TCPConnection ref, data: ByteSeq): ByteSeq ? =>
    """
    Called when data is sent on the connection. This gives the notifier an opportunity to modify sent data before it is written. The notifier can raise an error if the data is swallowed entirely.
    """
    data

  fun ref received(conn: TCPConnection ref, data: Array[U8] iso) =>
    """
    Called when new data is received on the connection.
    """
    None

  fun ref closed(conn: TCPConnection ref) =>
    """
    Called when the connection is closed.
    """
    None
```

If you read the documentation strings attached to _TCPConnectionNotify_'s methods, you can see that they are related to servicing individual connections. 

You might want to take the time now to check out [Deconstructing a Pony echo server](http://www.monkeysnatchbanana.com/2015/12/13/deconstructing-a-pony-echo-server/) to see _TCPListenNotify_ and _TCPConnectionNotify_ in action. It's not a required read but can add color and background that you might find helpful. Next, we are going to cover the basics of TCP/IP server programming which will set the table for our exploration of our main method in our echo server and our trip through the Pony and C code that makes up Pony's TCP stack.

## TCP/IP server basics

<img src="https://upload.wikimedia.org/wikipedia/en/5/55/Bsd_daemon.jpg" align="right">

In order to understand Pony's approach to network programming, it's important to understand the basics of the BSD socket API. According to Wikipedia:

>Berkeley sockets is an application programming interface (API) for Internet sockets and Unix domain sockets, used for inter-process communication (IPC). It is commonly implemented as a library of linkable modules.

>The API evolved with little modification from a de facto standard into a component of the POSIX specification. Therefore, the term POSIX sockets is essentially synonymous with Berkeley sockets. They are also known as BSD sockets, acknowledging the first implementation in the Berkeley Software Distribution.

The FreeBSD Developers' Handbook has an [excellent overview](https://www.freebsd.org/doc/en/books/developers-handbook/sockets-essential-functions.html) of the basics of BSD socket programming. I highly advise reading it if you aren't familiar with socket programming. You can however make it through this post while knowing only a subset of the information in the Developers' Handbook. 

Let's go step by step through the basics of creating a TCP/IP server using the BSD socket API:

**Create a socket**: It's basically ephemeral and attached to nothing. The only thing we know about are basic info such as its domain, protocol, and type. As of yet, our socket has no address and can't accept any incoming connections. The C function signature is: 

`int socket(int domain, int type, int protocol)`

**Bind**: We bind our new socket to an address and port pair. For example, if we wanted to bind to the standard HTTP port on localhost, we would bind to 127.0.0.1 on port 80. 

`int bind(int s, const struct sockaddr *addr, socklen_t addrlen)`

**Listen**: Once our socket is associated with an address, we can start listening for incoming connections. 

`int listen(int s, int backlog)`

**Accept**: When we receive a new connection, accept is called to create a new socket to handle that connection. Our original socket continues listening for more incoming connections while our new socket handles talking to our remote client.

`int accept(int s, struct sockaddr *addr, socklen_t *addrlen)`

To put this together, when writing a server using the BSD socket interface we:

* Create a new socket
* Bind it to an address/port combo
* Start listening for incoming connections
* Spawn new socket on demand to handle each incoming connection as they arrive

Go ahead and review those steps until you feel comfortable with them. If you are struggling to remember them, write them down so you can refer to them as we work through Pony's TCP stack code. Those basic steps will help keep you oriented as we progress.

## An echo server redux

<img src="https://www.cs.northwestern.edu/~agupta/_projects/networking/TCPClientServer/cs.gif" align="right">

Recapping our echo server code from last time, we are going to dive in from:

```
actor Main  
  new create(env: Env) =>
    TCPListener.ip4(recover Listener(env) end)
```

I previously described this code as:

>We start by creating a TCPListener that only handles ip version 4. TCPListener is an actor defined in the standard library. To create an ipv4 TCPListener, we have to provide one thing: a class that implements TCPListenNotify. That object will be notified by the TCPListener actor we are creating anytime a new connection comes in.

In that post, we didn't go into _TCPListener_ to see how it's implemented. Let's pull back that veil and move down another layer of abstraction.

## A little bit of TCP/IP in Pony

The Pony TCP stack is a powered by combination of callback objects and events. As we move through the code, this will become more and more clear. Let's take a look at the _TCPListener ipv4_ constructor that we called from our _Main_ actor in our echo server:

```
actor TCPListener

  new ip4(notify: TCPListenNotify iso, host: String = "",
    service: String = "0", limit: USize = 0)
  =>
    """
    Listens for IPv4 connections.
    """
    _limit = limit
    _notify = consume notify
    _event = @os_listen_tcp4[AsioEventID](this, host.cstring(), service.cstring())
    _fd = @asio_event_fd(_event)
    _notify_listening()
```

The first line we want to focus on is:

```
_event = @os_listen_tcp4[AsioEventID](this, host.cstring(), service.cstring())
```

Let's start with that ```@os_listen_tcp4[AsioEventID]```. What's going on there? It appears to be some kind of function call but it's unlike any we have previously seen. The _@_ indicates that the function ```os_listen_tcp4``` is implemented in C. The ```[AsioEventID]``` indicates that our return type is of the type ```AsioEventID```. That's as much as you need to know about Pony's C FFI to get through the rest of this post. If you are interested in learning more, check out the [calling c section of the Pony tutorial](http://tutorial.ponylang.org/c-ffi/calling-c/).

Let's check out what is going on in the C function ```os_listen_tcp4``` that we are calling:

```
asio_event_t* os_listen_tcp4(pony_actor_t* owner, const char* host,
  const char* service)
{
  return os_socket_listen(owner, host, service, AF_INET, SOCK_STREAM,
    IPPROTO_TCP);
}
```

That's pretty straight forward. It is just calling another C function ```os_socket_listen```. What's important to note and to keep an eye on as we work through this, is the ```pony_actor_t* owner```. Don't lose track of it. It's a pointer to _TCPListener_ actor and will be very important later. Anyway, continuing on, ```os_socket_listen```:
```
static asio_event_t* os_socket_listen(pony_actor_t* owner, const char* host,
  const char* service, int family, int socktype, int proto)
{
  struct addrinfo* result = os_addrinfo_intern(family, socktype, proto, host,
    service, true);

  struct addrinfo* p = result;

  while(p != NULL)
  {
    int fd = socket_from_addrinfo(p, true);

    if(fd != -1)
    {
      asio_event_t* ev = os_listen(owner, fd, p, proto);
      freeaddrinfo(result);
      return ev;
    }

    p = p->ai_next;
  }

  freeaddrinfo(result);
  return NULL;
}
```

The lines to focus on are:

```
asio_event_t* ev = os_listen(owner, fd, p, proto);
...
return ev;
```

Where we call ```os_listen``` and get an ```asio_event_id*``` back that will unwind its way back up the stack all the way to the Pony code in _TCPListener_ and be assigned to the ```_event``` variable:

```
_event = @os_listen_tcp4[AsioEventID](this, host.cstring(), service.cstring())
```

Before returning to _TCPListener_, we have more C code to follow. What's going on in ```os_listen```?

```
static asio_event_t* os_listen(pony_actor_t* owner, int fd,
  struct addrinfo *p, int proto)
{
  if(bind((SOCKET)fd, p->ai_addr, (int)p->ai_addrlen) != 0)
  {
    os_closesocket(fd);
    return NULL;
  }

  if(p->ai_socktype == SOCK_STREAM)
  {
    if(listen((SOCKET)fd, SOMAXCONN) != 0)
    {
      os_closesocket(fd);
      return NULL;
    }
  }

  // Create an event and subscribe it.
  asio_event_t* ev = asio_event_create(owner, fd, ASIO_READ, 0, true);

  (void)proto;

  return ev;
}
```

There we go! In all that C code, I see some BSD socket code:

```
if(bind((SOCKET)fd, p->ai_addr, (int)p->ai_addrlen) != 0)
```

where we bind our socket and 

```
if(listen((SOCKET)fd, SOMAXCONN) != 0)
```

where we start listening on that socket.

If you remember our BSD socket creation steps earlier we had:

**socket -> bind -> listen** -> accept

Now that we are listening, how do we end up accepting incoming connections? The key lies in Pony's internal event system. Looking at the end of ```os_listen```, you'll see:

```
// Create an event and subscribe it.
asio_event_t* ev = asio_event_create(owner, fd, ASIO_READ, 0, true);
```

Let's check out what is going on in ```asio_event_create```. N.B. that our first parameter is the ```pony_actor_t* owner``` that is a pointer to our _TCPListener_ actor that has been weaving its way down through the code.

```
asio_event_t* asio_event_create(pony_actor_t* owner, int fd, uint32_t flags, uint64_t nsec, bool noisy)
{
  if((flags == ASIO_DISPOSABLE) || (flags == ASIO_DESTROYED))
    return NULL;

  pony_type_t* type = *(pony_type_t**)owner;
  uint32_t msg_id = type->event_notify;

  if(msg_id == (uint32_t)-1)
    return NULL;

  asio_event_t* ev = POOL_ALLOC(asio_event_t);

  ev->magic = ev;
  ev->owner = owner;
  ev->msg_id = msg_id;
  ev->fd = fd;
  ev->flags = flags;
  ev->noisy = noisy;
  ev->nsec = nsec;

  // The event is effectively being sent to another thread, so mark it here.
  pony_ctx_t* ctx = pony_ctx();
  pony_gc_send(ctx);
  pony_traceactor(ctx, owner);
  pony_send_done(ctx);

  asio_event_subscribe(ev);
  return ev;
}
```

The important take away from ```asio_event_create``` is that it creates a new event for ```ASIO_READ``` and passes that event to ```asio_event_subscribe```. We won't go any further into Pony's event system at this time, suffice it to say that ```asio_event_subscribe``` is the entry into events being sent on Pony and has several different implementations based on the asio backing implementation. The current options are platform specific and one of epoll, kqueue, iocp.

Great! Now we are bound and listening and are ready to receive events related to our socket.

## Back to our echo server

<img src="https://t07.deviantart.net/JyMOqvGHj7ZX4s7XelqnI86rk8g=/300x200/filters:fixed_height(100,100):origin()/pre03/3fd6/th/pre/i/2013/265/e/1/night_watch_the_bat_pony_2_by_zee66-d6nfuuc.png" align="right">

So we have a socket bound and listening. What now? Let's take a look again inside _TCPListener's ip4_ constructor and see how it triggers our first callback ```listening``` on our _TCPListenNotify_ implementor.

```
actor Main  
  new create(env: Env) =>
    TCPListener.ip4(recover Listener(env) end)

actor TCPListener
  new ip4(notify: TCPListenNotify iso, host: String = "",
    service: String = "0", limit: USize = 0)
  =>
    """
    Listens for IPv4 connections.
    """
    _limit = limit
    _notify = consume notify
    _event = @os_listen_tcp4[AsioEventID](this, host.cstring(),
      service.cstring())
    _fd = @asio_event_fd(_event)
    _notify_listening()
```

Note the last line in the _ip4_ constructor:

```
_notify_listening()
```

And its corresponding implementation later in _TCPListener_:

```
  fun ref _notify_listening() =>
    """
    Inform the notifier that we're listening.
    """
    if not _event.is_null() then
      _notify.listening(this)
    else
      _closed = true
      _notify.not_listening(this)
    end
```

The ```_notify.listening``` method calls ```listening``` on our callback object ```_notify```. Over in our echo server, we have the rather uninteresting:

```
  fun ref listening(listen: TCPListener ref) =>
    try
      (_host, _service) = listen.local_address().name()
      _env.out.print("listening on " + _host + ":" + _service)
    else
      _env.out.print("couldn't get local address")
      listen.close()
    end
```

But hey, we're now listening on our socket and we've printed out a log message. Exciting? Maybe. So we've gone from *Socket* to *Bind* to *Listen* and all that is left is accepting and handling incoming connections.

## Accepting a connection

<img src="https://img04.deviantart.net/d968/i/2014/078/7/f/vampire_pony_sisters_by_magister39-d7au3ef.png" width="200" align="right">

You might remember from earlier that in ```os_listen``` we used ```asio_event_subscribe``` to register that our _TCPListener_ instance was interested in knowing about ```ASIO_READ``` events on our socket. Whenever an event is generated, it will be delivered to our actor by calling its ```_event_notify``` behavior.

```
  be _event_notify(event: AsioEventID, flags: U32, arg: U32) =>
    """
    When we are readable, we accept new connections until none remain.
    """
    ...

    if AsioEvent.readable(flags) then
      _accept(arg)
    end

    ...
```

You can see that if our event is readable, we'll call the ```_accept``` method on our actor:

```
    if AsioEvent.readable(flags) then
      _accept(arg)
    end
```

Let's check out what is going on in ```_accept```:

```
  fun ref _accept(ns: U32 = 0) =>
    """
    Accept connections as long as we have spawned fewer than our limit.
    """
    ...

    while (_limit == 0) or (_count < _limit) do
      var fd = @os_accept[U32](_event)

      match fd
      | -1 =>
        // Something other than EWOULDBLOCK, try again.
        None
      | 0 =>
        // EWOULDBLOCK, don't try again.
        return
      else
        _spawn(fd)
      end
    end

    _paused = true
```

The important line to focus on is where we make another C FFI call, this time to ```@os_accept[U32]```. Returning back to the C code in the Pony runtime library, we see that ```os_accept``` is defined as:

```
int os_accept(asio_event_t* ev)
{
  int ns = accept(ev->fd, NULL, NULL);

  ...

  return (int)ns;
}
```

And there, we see another BSD socket call:

```
int ns = accept(ev->fd, NULL, NULL);
```

Which means that we are pretty close to completing our chain **Socket -> Bind -> Listen -> Accept**.

Once the connection is accepted, we return to ```_accept``` where we verify that everything is kosher with our new connection and then call ```_spawn```:
```
    while (_limit == 0) or (_count < _limit) do
      var fd = @os_accept[U32](_event)

      match fd
      | -1 =>
        // Something other than EWOULDBLOCK, try again.
        None
      | 0 =>
        // EWOULDBLOCK, don't try again.
        return
      else
        _spawn(fd)
      end
    end
```

Let's check out what is going on in Spawn.
```
  fun ref _spawn(ns: U32) =>
    """
    Spawn a new connection.
    """
    try
      TCPConnection._accept(this, _notify.connected(this), ns)
      _count = _count + 1
    else
      @os_closesocket[None](ns)
    end
```

The important line to focus on is:

```
TCPConnection._accept(this, _notify.connected(this), ns)
```

There's actually a lot going on in that one line so let's take a moment to walk through it. First, we call the ```connected``` method on our ```_notify``` callback object. In our current context, ```_notify``` is our listener callback object:

```
  fun ref connected(listen: TCPListener ref) : TCPConnectionNotify iso^ =>
    Server(_env)
```

Here, we are creating a Server object that implements _TCPConnectionNotify_ and will handle connections to our echo server. This notifier is in turn passed into the _TCPConnection_ actor's ```_accept``` constructor back in our ```_spawn``` method:

```
TCPConnection._accept(this, _notify.connected(this), ns)
```

Let's check out _TCPConnection_'s ```_accept``` constructor:

```
actor TCPConnection

  new _accept(listen: TCPListener, notify: TCPConnectionNotify iso, fd: U32) =>
    """
    A new connection accepted on a server.
    """
    _listen = listen
    _notify = consume notify
    _connect_count = 0
    _fd = fd
    _event = @asio_event_create(this, fd, AsioEvent.read_write(), 0, true)
    _connected = true

    _notify.accepted(this)
```

You can see we set up an event via a C FFI call to ```@asio_event_create``` and finally, call the ```_accepted``` method on our _Server_ callback object.

Our accepted callback gives us a chance to do interesting things upon accepting a new connection, in our case, "interesting" means logging an informational message:

```
class Server is TCPConnectionNotify  

  fun ref accepted(conn: TCPConnection ref) =>
    _env.out.print("connection accepted")
```

And handling connection input? Again, it comes from the depths of the event system. Our actor is notified of an event via the ```_event_notify``` behavior. 

```
  be _event_notify(event: AsioEventID, flags: U32, arg: U32) =>
    """
    Handle socket events.
    """
    ...

    if AsioEvent.readable(flags) then
      _readable = true
      _complete_reads(arg)
      _pending_reads()
    end

    ...
  end
```

I've stripped out a lot of code from ```_event_notify``` to draw your attention more easily to the one line we really care about, the call to the private method `_pending_reads`.

```
  fun ref _pending_reads() =>
    """
    Read while data is available, guessing the next packet length as we go. If
    we read 4 kb of data, send ourself a resume message and stop reading, to
    avoid starving other actors.
    """
    try
      var sum: USize = 0

      while _readable and not _shutdown_peer do
        // Read as much data as possible.
        let len = @os_recv[USize](_event, _read_buf.cstring(), _read_buf.space()) ?

        var next = _read_buf.space()

        ...

        let data = _read_buf = recover Array[U8].undefined(next) end
        data.truncate(len)
        _notify.received(this, consume data)

        ...
      end
    ...
```

Again there's a lot of work going on in this method, there's a lot of book keeping, a call to the C function that gets data from the socket (```@os_recv```) and most importantly, the invocation of the ```received``` method on our Server callback:

```
_notify.received(this, consume data)
```

Which means, we've finally arrived at the ```received``` method on our Server class where we take the data our echo server has received and send it back out to the client:

```
fun ref received(conn: TCPConnection ref, data: Array[U8] iso) =>
    _env.out.print("data received, looping it back")
    conn.write("server says: ")
    conn.write(consume data)
```

## Wrapping up

We've made our way though a lot of Pony and C code to get to this point where we can see how our simple echo server works.
I hope by now you feel like you have a grasp on how BSD socket programming works and nice event based abstractions that Pony provides for working with it. If you are interested in learning more about TCP/IP programming, I highly recommend you pick up all 3 volumes of W. Richard Steven's classic _TCP/IP Illustrated_ series:

* [TCP/IP Illustrated, Volume 1: The Protocols](http://www.amazon.com/TCP-Illustrated-Protocols-Addison-Wesley-Professional/dp/0321336313/ref=sr_1_1?ie=UTF8&qid=1450229478&sr=8-1&keywords=tcp+ip+illustrated) 
* [TCP/IP Illustrated: The Implementation, Vol. 2](http://www.amazon.com/TCP-IP-Illustrated-Implementation-Vol/dp/020163354X/ref=sr_1_3?ie=UTF8&qid=1450229478&sr=8-3&keywords=tcp+ip+illustrated)
* [TCP/IP Illustrated, Vol. 3: TCP for Transactions, HTTP, NNTP, and the UNIX Domain Protocols](http://www.amazon.com/TCP-Illustrated-Vol-Transactions-Protocols/dp/0201634953/ref=sr_1_4?ie=UTF8&qid=1450229478&sr=8-4&keywords=tcp+ip+illustrated)

Next time, we'll dig into Pony's event system and explore what's going on inside ```asio_event_subscribe```.
