+++
tags = ["pony"]
author = "Sean T. Allen"
date = "2015-12-13T10:56:41-05:00"
title = "Deconstructing a Pony echo server"
slug = "deconstructing-a-pony-echo-server"
draft = false
+++

Lately I've been diving into learning [Pony](http://ponylang.org) in a more organized fashion. As part of that, I've decided to share the experience along the way. If you aren't familiar with Pony then you probably won't get much from this post. If you are interested in a high performance, safe, actor based programming language, then I'd suggest you check out the [Pony tutorial](http://tutorial.ponylang.org) then venture back. All that said, I'll do my best to provide links to relevant Pony documentation throughout this post.

This morning's exercise was to write an echo server and see what bits of Pony I'd learn along the way. What follows is the complete original source code for my Pony echo server and then some discussion of what I learned as I was writing it.

If you want to get started writing any network services with Pony, I'd suggest by started by reading the ["net" example](https://github.com/ponylang/ponyc/tree/master/examples/net). My echo server borrows heavily from the example code. My basic process was to steal bits from the example code until I had a working echo server and then set about figuring out how it all actually worked. 

Hopefully, you find this useful. I'm going to start by dropping all the code on you at once, don't worry about absorbing it all. We'll walk through the important parts together. Without further ado, _echo.pony_: 

```
use "net"

actor Main
  new create(env: Env) =>
    TCPListener.ip4(recover Listener(env) end)

class Listener is TCPListenNotify
  let _env: Env
  var _host: String = ""
  var _service: String = ""

  new create(env: Env) =>
    _env = env

  fun ref listening(listen: TCPListener ref) =>
    try
      (_host, _service) = listen.local_address().name()
      _env.out.print("listening on " + _host + ":" + _service)
    else
      _env.out.print("couldn't get local address")
      listen.close()
    end

  fun ref not_listening(listen: TCPListener ref) =>
    _env.out.print("couldn't listen")
    listen.close()

  fun ref connected(listen: TCPListener ref) : TCPConnectionNotify iso^ =>
    Server(_env)

class Server is TCPConnectionNotify
  let _env: Env

  new iso create(env: Env) =>
    _env = env

  fun ref accepted(conn: TCPConnection ref) =>
    _env.out.print("connection accepted")

  fun ref received(conn: TCPConnection ref, data: Array[U8] iso) =>
    _env.out.print("data received, looping it back")
    conn.write("server says: ")
    conn.write(consume data)

  fun ref closed(conn: TCPConnection ref) =>
    _env.out.print("server closed")
```

First important thing to note is that none of this will work without some classes from the [Pony standard networking library](https://github.com/ponylang/ponyc/tree/master/packages/net). We include those classes we might need with the _use_ expression:

```
use "net"
```

Every Pony program has a _Main_ actor that acts as its entry point. You can get more details about special significance of _Main_ in the ["hello-world" section of the Pony tutorial](http://tutorial.ponylang.org/getting-started/hello-world.html).

Let's take a look at our echo server's _Main_ actor:

```
actor Main
  new create(env: Env) =>
    TCPListener.ip4(recover Listener(env) end)
```

There's quite a bit going on here for a newbie to absorb. It took me a while with the examples and the standard library to understand how to get started with network programming in Pony. Let's unpack the important bits.

```
01: TCPListener.ip4(
02:   recover
03:     Listener(env)
04:   end
05: )
```

We start by creating a TCPListener that only handles ip version 4. _TCPListener_ is an actor [defined in the standard library](https://github.com/ponylang/ponyc/blob/master/packages/net/tcplistener.pony). To create an ipv4 TCPListener, we have to provide one thing: a class that implements [_TCPListenNotify_](https://github.com/ponylang/ponyc/blob/master/packages/net/tcpnotify.pony#L61). That object will be notified by the TCPListener actor we are creating anytime a new connection comes in. 

Here's our _Listener_ from the echo server:

```
class Listener is TCPListenNotify
  let _env: Env
  var _host: String = ""
  var _service: String = ""

  new create(env: Env) =>
    _env = env

  fun ref listening(listen: TCPListener ref) =>
    try
      (_host, _service) = listen.local_address().name()
      _env.out.print("listening on " + _host + ":" + _service)
    else
      _env.out.print("couldn't get local address")
      listen.close()
    end

  fun ref not_listening(listen: TCPListener ref) =>
    _env.out.print("couldn't listen")
    listen.close()

  fun ref connected(listen: TCPListener ref) : TCPConnectionNotify iso^ =>
    Server(_env)
```

Basically, you can sum up what it does by saying:

* When it starts up, it prints out the host and port it's listening on
* When a new connection is established, it creates a new instance of _Server_ to handle the incoming connection

Our Server class implements the [_TCPConnectionNotify_ interface](https://github.com/ponylang/ponyc/blob/master/packages/net/tcpnotify.pony#L1) as required by _TCPListenNotify_.

```
class Server is TCPConnectionNotify
  let _env: Env

  new iso create(env: Env) =>
    _env = env

  fun ref accepted(conn: TCPConnection ref) =>
    _env.out.print("connection accepted")

  fun ref received(conn: TCPConnection ref, data: Array[U8] iso) =>
    _env.out.print("data received, looping it back")
    conn.write("server says: ")
    conn.write(consume data)

  fun ref closed(conn: TCPConnection ref) =>
    _env.out.print("server closed")
``` 

We can sum up what _Server_ is doing with:

* Outputs a message to standard out any time it accepts a connection.
* When it receives data, it sends it back to the sender with an additional _"server says: "_ message.

There's one interesting bit of Pony in our Server class:

```
  fun ref received(conn: TCPConnection ref, data: Array[U8] iso) =>
    _env.out.print("data received, looping it back")
    conn.write("server says: ")
    conn.write(consume data)
```

What's up with that _consume data_ that is being passed to _conn.write_? It's part of [Pony's reference capabilities](http://tutorial.ponylang.org/capabilities/reference-capabilities.html). Reference capabilities are one of Pony's killer features. As programmers, we can mark data with different capabilities allowing us, with the support of the compiler, to safely use shared mutable state. If you aren't familiar with Pony's reference capabilities, I suggest you [review them](http://tutorial.ponylang.org/capabilities/reference-capabilities.html) before continuing on.

Right now, the two capabilities that we care about are _isolated_ and _value_. They are defined in the Pony tutorial as:

> Isolated, written iso. This is for references to isolated data structures. If you have an iso variable then you know that there are no other variables that can access that data. So you can change it however you like and give it to another actor.

> Value, written val. This is for references to immutable data structures. If you have a val variable then you know that no-one can change the data. So you can read it and share it with other actors.

The type signature for TCPConnection write is:

```
be write(data: ByteSeq)
```

write takes a ByteSeq _value_. However, our data variable is tagged as being an _isolated_ capability. If we were to try and pass our _iso data_ to our _val write_, we'd get the following compiler error:

```
echo.pony:43:16: argument not a subtype of parameter
    conn.write(data)
               ^
packages/net/tcpconnection.pony:75:12: parameter type: ByteSeq val
  be write(data: ByteSeq) =>
           ^
echo.pony:43:16: argument type: Array[U8 val] iso!
    conn.write(data)
```

We need to turn our iso into a val. By doing that, we are widening the access to it. Pretty dangerous stuff. When you need to expand capabilities in that fashion, Pony provides the [consume keyword](http://tutorial.ponylang.org/capabilities/consume-and-destructive-read.html#consuming-a-variable). When we consume our iso data, we are creating a new variable that is a val and declaring that from this point forward, no one can use the original data variable. If we were to try to access the data variable after consuming it, we'd get a compiler error.

We've covered a lot of ground and ended up stumbling around in [Pony's reference capabilities](http://tutorial.ponylang.org/capabilities/reference-capabilities.html) which are one of the hardest parts of the language to get a handle on. There's still one bit of our echo server that we haven't tackled yet. Earlier, when discussing our _Main_ actor, we had this code:

```
01: TCPListener.ip4(
02:   recover
03:     Listener(env)
04:   end
05: )
```

We never discussed what was going on with lines 02 and 04. What up with that recover? Again, the answer lines in [Pony's reference capabilities](http://tutorial.ponylang.org/capabilities/reference-capabilities.html). The method signature for TCPListener.ip4 says that the notify handler we supply has to be an iso reference. However, our Listener is a reference. _recover_ in this case takes our ref and returns an iso. I won't dig into the details as the Pony tutorial has a good [section on recover](http://tutorial.ponylang.org/capabilities/recovering-capabilities.html).

Lastly, I'll add that I realized as I was writing this post, that I didn't need to use recover at all. I was using it because I took it from the ["net" example code](https://github.com/ponylang/ponyc/tree/master/examples/net). If we were to change our _Listener_ classes constructor from returning a ref:

```
  new create(env: Env) =>
    _env = env
```

to returning an iso:

```
  new iso create(env: Env) =>
    _env = env
```

then our _Main_ actor can become the far more straightforward:

```
actor Main
  new create(env: Env) =>
    let listener = TCPListener.ip4(Listener(env))
```

The final code is currently available on [GitHub](https://github.com/SeanTAllen/pony-echo-server) and will be making it into the official Pony examples. Hopefully you've learned a little something. I know I learned a quite bit having to explain what I did this morning. Check back soon, there will be plenty more learning Pony content coming.

_12/14/15 update: the echo server is now available as part of the [official ponyc examples](https://github.com/ponylang/ponyc/blob/master/examples/echo/echo.pony)._

