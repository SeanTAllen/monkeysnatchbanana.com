+++
author = "Sean T. Allen"
slug = "on-becoming-a-better-teacher"
draft = false
date = "2015-04-12T11:24:38-05:00"
title = "On Becoming a Better Teacher"

+++

Sometime in early 2013, I was really struggling with writing [Storm Applied](http://manning.com/sallen/?a_aid=sallen). I felt stymied at every turn by the requests of our editor. He was always asking us to explain simple topics more deeply. I almost lost my mind when a request to explain “web-scale” came up. It all felt like Manning was having us dumb the book down. Here we were trying to write an “advanced” book and we were running around explaining obvious, simple topics. In short, I was frustrated, angry and ready to quit.

![Definition of web-scale from Storm Applied](/img/post/on-becoming-a-better-teacher/Definition-of-web-scale-from-Storm-Applied.png)

I'll admit to a certain level of elitism that I carry through my life. As an example, there's a series of books designed to teach various aspects of being a programmer called [Head First](http://shop.oreilly.com/category/series/head-first.do). I'd always looked down on them. They weren't books for “real programmers”. In my mind, they were written for lazy people who weren't willing to invest thought into teaching themselves new topics. And here was our editor at Manning, asking us to do all these things that had me mumbling “this isn't a crappy Head First book”. And then, it happened: I was following Kathy Sierra, co-creator of the Head First series, on Twitter and she started tweeting about learning. How everyone learns differently. An explanation that makes sense to you, won't always make sense to the next person. And the explanation that resonates with them, won't with you. That to be an effective teacher, you need to be willing and able to explain any topic, no matter how simple or complicated, numerous ways. What followed was a couple of conversations between Kathy and myself that changed the way I viewed the requests from Manning and my attitude in general.

What Kathy taught me was something that had been staring me in the face the entire time. I do a lot of mentoring and teaching as part of my job. This is almost always in person, often to a group of people rather than one on one. When I'm teaching something, I can tell who is understanding an explanation and who isn't just by looking at people's faces. When I see someone not understanding what I'm explaining, I always stop and try explaining it another way; often asking them questions to determine what they have understood and what is still unclear. You can't do that with a book. You can't see confusion on a reader's face. You can't then explain the subject matter in another way. You have to anticipate those issues ahead of time. This seems incredibly obvious to me now, but back in the winter of 2013, I was completely blind to this idea. I wish I could say I had an epiphany, but it took me some time to really absorb the lesson. I understood the idea in concept, but it hadn't fully taken root. Around that time though, something happened at work to really drive that point home.

We were introducing a couple of new developers on our team at TheLadders to Storm and it became clear they had very little idea how to use the Storm UI. I was very versed in the UI and considered it extremely simple. It was always my first stop when diagnosing problems in our production Storm cluster. I started teaching people how to use the Storm UI to do what I did and it hit me: Here was a topic I was going to have to teach in Storm Applied and I was doing the “explain it many different ways” trick with my co-workers. The book would need to do it as well. Kathy was completely right. So was our editor at Manning. I was just too proud and stubborn to admit it.

I started in on Storm Applied again with renewed vigor. I was no longer considering dropping out of the project because it was being “dumbed down”. I started approaching every topic with the question “what is obvious to me that won't be to someone just learning this”. It's really hard to do. One of the hardest things I've had to do. To drill down, through all my professional experience and say “what do I know that others don't that I'm assuming they will know”. Those conversations with Kathy have made me a better teacher and a better writer.

A couple of examples of how this played out:

* Chapter 8 in Storm Applied is about diving below the basic abstractions that Storm provides you as a programmer and looking at how they are implemented. Before I wrote that chapter, I taught 5 different groups of people the same material, each time taking the questions they asked and building it into how I taught it the next time. 

* Chapter 5 includes a 12 page review of the Storm UI. It's very straight-forward. Lots of screenshots calling out and highlighting certain parts of different screens saying ”and this important bit is…”. 

![Example Storm UI screenshot from Storm Applied](/content/images/2015/04/Storm-UI-Figure-from-Storm-Applied.png)

For some people, this might be redundant and seem pointless. An otherwise glowing review of [Storm Applied on Amazon](http://www.amazon.com/Storm-Applied-Strategies-real-time-processing/dp/1617291897/ref=sr_1_1) includes the following:

> What I didn't love:
>
> There only minor issue that I have with the book is that section on the Storm UI seemed like "filler". The UI is not very complex, and it is very self-explanatory once you know the basic Storm concepts and terminology. The numerous screenshots and descriptions in the book could have easily been left out with no real detriment to the reader. I would recommend skimming or skipping these sections.

I understand that comment quite well. I said something similar to Matt and Peter when we were discussing how much we should cover the UI when we were first planning the book. I said in my [previous post about Storm Applied](http://www.monkeysnatchbanana.com/2015/04/04/storm-applied/):

> I don't remember now what I envisioned the book being when we first signed the contract. I know that Storm Applied isn't that book but I'm quite happy with it nonetheless.

That “advanced book” I was planning on writing? It's a distant memory now. I can still sort of remember what it would have been like but that book wouldn't have been as good as Storm Applied is. And so, I'm quite happy with reviews that call out “filler” and repetition because I know why its there. And now you do as well.
