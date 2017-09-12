+++
title = "Pony Patterns: Waiting"
tags = ["pony"]
author = "Sean T. Allen"
slug = "pony-patterns-waiting"
draft = false
date = "2016-01-16T10:46:33-05:00"

+++

> I am a patient boy. I wait, I wait, I wait, I wait. My time is water down a drain
> 
> Everybody's moving. Everybody's moving.
> Everything is moving, moving, moving, moving
> 
> Please don't leave me to remain.
> In the waiting room
>
> --- Ian MacKaye

How do you wait when you can't wait? No, that isn't a riddle; it's a question I recently faced while writing some [Pony](http://www.ponylang.org) code for [work](https://www.wallaroolabs.com). 

Here's the problem: I'm writing a black box testing application that will verify the correctness of our system under test. My black box tester sends information into the box via UDP and gets data back via the same means and verifies that the data is valid. That system under test is currently a prototype written in Python. All things considered, it performs well. The problem is Pony performs better. 

When I first fired up my tester, it quickly swamped the prototype. We haven't implemented any sort of backpressure yet so, I knew I needed to slow my application down via more "manual" means. I needed to limit the rate it was supplying data to the system under test. But how? 

In a language with blocking operations, I could just call sleep and be done with it. It might not be the most elegant solution but it would work. Pony, however, isn't such a language. One of Pony's key features is there are no blocking operations. So, back to our original question: how do you wait when you can't wait? 

After a bit of digging around, we came across the [Timer](https://github.com/CausalityLtd/ponyc/blob/master/packages/time/timer.pony) class. A timer allows you to execute code at set intervals. I'm going to walk you through how to use a timer using a simple application that prints out a number to the console every 5 seconds until someone terminates the program:

```
use "time"

actor Main
  new create(env: Env) =>
    let timers = Timers
    let timer = Timer(NumberGenerator(env), 0, 5_000_000_000)
    timers(consume timer)

class NumberGenerator is TimerNotify
  let _env: Env
  var _counter: U64

  new iso create(env: Env) =>
    _counter = 0
    _env = env

  fun ref _next(): String =>
    _counter = _counter + 1
    _counter.string()

  fun ref apply(timer: Timer, count: U64): Bool =>
    _env.out.print(_next())
    true
```

Zooming in on the key bits, we first set up our timers, create one and add it to our set of timers:

```
    let timers = Timers
    let timer = Timer(NumberGenerator(env), 0, 5_000_000_000)
    timers(consume timer)
```

The Timer constructor takes 3 arguments, the class to notify, how long until our timer expires and how often to fire. In our example code an instance of NumberGenerator will be called every 5 billion nanoseconds i.e. every 5 seconds until the program is killed.

Here's our method in NumberGenerator that gets executed:

```
  fun ref apply(timer: Timer, count: U64): Bool =>
    _env.out.print(_next())
    true
```

If we were to compile and run our application, we'd end up with some output like:

![program output](/img/post/pony-patterns-waiting/Screenshot-2016-01-18-16-51-54.png)

It's not the most exciting output in the world but, it's a pattern that I expect many Pony users will need: '[how to wait without waiting](https://www.youtube.com/watch?v=cMOAXm94VWo)'.

---

_If you are interested in what is going on with the `consume` in the `timers(consume timer)`, check out my previous post [Deconstructing a Pony echo server](http://www.monkeysnatchbanana.com/2015/12/13/deconstructing-a-pony-echo-server/) where I cover the semantics of consume._



