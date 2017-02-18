+++
date = "2017-02-18T09:24:45-05:00"
title = "Why Pony?"
tags = ["pony","erlang","c"]
author = "Sean T. Allen"
slug = "why-pony"
draft = true

+++

Early in 2015, [Pony](http://www.ponylang.org) a high performance actor based language caught my eye. Pony's feature set excites me quite a bit, however, the language is very immature. Making the decision to base a production application on new, immature technology is fraught with uncertainty. I've spent a lot of time thinking about where it might be appropriate to leverage Pony. 

[The Pony philosophy](https://github.com/CausalityLtd/ponyc/wiki/Philosophy):

> Correctness. Incorrectness is simply not allowed. It's pointless to try to get stuff done if you can't guarantee the result is correct.

> Performance. Runtime speed is more important than everything except correctness. If performance must be sacrificed for correctness, try to come up with a new way to do things. The faster the program can get stuff done, the better. This is more important than anything except a correct result.

> Simplicity. Simplicity can be sacrificed for performance. It is more important for the interface to be simple than the implementation. The faster the programmer can get stuff done, the better. It's ok to make things a bit harder on the programmer to improve performance, but it's more important to make things easier on the programmer than it is to make things easier on the language/runtime.

> Consistency. Consistency can be sacrificed for simplicity or performance. Don't let excessive consistency get in the way of getting stuff done.

> Completeness. It's nice to cover as many things as possible, but completeness can be sacrificed for anything else. It's better to get some stuff done now than wait until everything can get done later. 


## The case of Pony v Erlang

People often compare Pony to Erlang because they are both actor based. It's a natural comparison to want to make. A lot of the people I see getting interested in Pony are coming from an Erlang background. While it's appropriate to compare the goals of the language, you shouldn't be formulating questions like- 'Should I use Erlang or should I use Pony?' Erlang is a very mature language that has been in existence for over 20 years. Pony is less than 5 years old. Extensive native tooling exists in the Erlang ecosystem. The vast majority of Pony tooling is C tooling. With Erlang, you are going to have access to the OTP libraries that will make building distributed systems much easier. You'll have access to QuickCheck. In short, you are getting a ton of tooling maturity that Pony can't provide any time in the near future.

## The case of Pony v C

If writing your application in C is something you are seriously considering, then there is a case for Pony. Pony started its life as an actor library that was callable from C and you can still [use Pony in that fashion](http://bluishcoder.co.nz/2015/12/16/c-linkable-libraries-with-pony.html). Pony and C integration is excellent. At this point in its life, I consider Pony to an excellent complement to C. You can use existing C tooling with Pony while leveraging Pony's type system and concurrency model to provide a better, safer concurrency model.

If you are looking at a C project and think:

* The Actor model would be a good concurrency model for your project 
* You'd like the compiler support to verify you are sharing memory safely

then Pony might be right for you. The right way to think of Pony is as a better C that provides an excellent high performance, safe concurrent programming model based on actors.
