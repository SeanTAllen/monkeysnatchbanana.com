+++
title = "QCon NY: Pony"
tags = ["talks", "pony", "stream processing", "video", "slides"]
description = "Post with link to my 2017 QCon New York talk \"Pony: How I learned to stop worrying and embrace an unproven technology\" and associated content."
author = "Sean T. Allen"
slug = "qcon-ny-17-pony"
draft = false
date = "2017-09-02T10:20:46-05:00"

+++

## Pony: How I learned to stop worrying and embrace an unproven technology

Video of my QCon New York talk: ["Pony- How I learned to stop worrying and embrace an unproven technology"](https://www.infoq.com/presentations/pony-wallaroo) is now available. 

The talk details my experiences thus far in using [Pony](https://www.ponylang.org) at [Sendence](https://twitter.com/sendenceeng) to build Wallaroo, a high-performance stream processing system. The talk was part of a FinTech track so there's a slight Fintech bent to some of the content that probably wouldn't have been in the talk otherwise.

---

There's a couple of links at the end of the talk for the additional material you can check out. To make life easier on everyone I'm recreating it here.

### Trash Day: Coordinating Garbage Collection in Distributed Systems

["Trash Day"](https://www.usenix.org/system/files/conference/hotos15/hotos15-paper-maas.pdf) is an awesome paper on how coordinating garbage collection pauses in Apache Spark, and Apache Cassandra clusters improved performance.

### Ownership and Reference Counting based Garbage Collection in the Actor World

More commonly known as the ["ORCA paper"](https://www.ponylang.org/media/papers/OGC.pdf). This article by Sylvan Clebsch et al. dives into the inner-workers of the Pony garbage collector.

---
If you are interested, I've made the [slides available on Speakerdeck](https://speakerdeck.com/seantallen/pony-how-i-learned-to-stop-worrying-and-embrace-an-unproven-technology). Like most of my talks, the slides aren't particularly good at standing on their own without the talk itself.
