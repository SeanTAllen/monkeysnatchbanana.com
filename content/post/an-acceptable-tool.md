+++
title = "An Acceptable Tool"
tags = ["software architecture"]
author = "Sean T. Allen"
slug = "an-acceptable-tool"
draft = false
date = "2015-02-24T11:31:27-05:00"

+++

Imagine for a moment that you are on a small development team tasked with core operations at a moderate sized startup. You're responsible for the development, operations and maintenance of various production systems. Your day is filled with all the fun of programming combined with the joys of running a distributed system. You've just entered a room with the rest of your teammates to discuss what tools you'll be using to build your latest system. 

You're fairly far along in the process; down to an Erlang based solution and a JVM based one. The Erlang solution is very alluring. Erlang's OTP library handles a ton of concerns for you that you will otherwise have to handle yourself with the JVM solution. Erlang is "the right tool for the job". However, you are going in to the room to argue for the JVM solution. Why? Because you don't need the right tool, you just need "an acceptable tool".

You don't run any Erlang based systems in production. You have no experience with monitoring Erlang, collecting metrics or all the other things that go into running a stable system. The JVM on the other hand, you have tons of experience with. You and your team mates are proficient at tuning the garbage collector to minimize latency. You have extensive Java profiling experiencing. You have battle tested metrics collecting and other libraries that you've been running in production without issue. 

The JVM might not be the right tool, but it isn't the wrong one either. It's acceptable. It will get the job done and most importantly you know how to get the job done with it. Operational knowledge is hard won. Far harder to win than understanding the syntax and semantics of a new programming language. 

In the first few weeks after your new project is released into production, you'll be thankful you picked the merely acceptable tool because you spend less time learning how to fight the inevitable fires and more time sleeping peacefully at night.

What's the difference between the right tool and an acceptable one? It's a matter of context and costs. Every tool comes with a cost that varies based on the context in which it's used. In a production environment, operational experience should factor heavily into that cost analysis. Picking an acceptable tool is hard. It requires research and understanding. Its easy to fall into the trap of thinking you are picking an acceptable tool when really you're just picking the tool at hand.
