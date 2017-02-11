+++
author = "Sean T. Allen"
slug = "learning-from-ada"
draft = false
tags = ["c","ada"]
date = "2016-02-22T10:42:22-05:00"
title = "Learning From Ada"
+++

This is a cautionary tale. One of youth and a lesson I eventually learned but still often don't heed. About how sometimes, the tool that is easiest to get started with isn’t the tool that will make your job the easiest.

When I was getting started as a professional programmer, I was devouring languages left and right, trying them out for a few days before moving on to others. From this, I stuck with a few. My first "professional" languages were Perl, Pascal, UserLand Frontier, and AppleScript. During my first couple of years programming, I either released some little bit of open source software or got paid to write something using one of them. Pascal was my favorite. It had the best performance and it was a "real language" that allowed me to scratch my itch for writing system software. For reasons I no longer remember, I started looking around for a "better" systems language. The two that I settled on were [C](https://en.wikipedia.org/wiki/C_(programming_language)) and [Ada](https://en.wikipedia.org/wiki/Ada_(programming_language)). Why I came to each is less important than how I made decided between them and why I still regret that decision.

Ada's reputation, or at least what had filtered down to me, was pretty cool. It was built for safety. It was used at the Department of Defense and to do all sorts of awesome cool-sounding stuff, but given my level of experience, most of its features meant little to me. I set about trying to learn Ada. Over the course of two weeks, I slowly grew more and more frustrated with Ada. It took me forever to get any of my programs to compile. I was being asked to think more than I had with other languages I had previously used and even then, the compiler regularly frustrated me. After a couple weeks of this, I felt inadequate, frustrated and ready to try something else; enter C.

I quickly fell in love with C. It felt much simpler than Ada. It was much easier to get my code to compile. There were more books, the community seemed larger and I knew that Apple was moving the Macintosh APIs from Pascal to C. So many things lined up to rationalize using C. In the end though, there was one factor that I know was more important than any other. The C compiler made me feel adequate. Unlike Ada, I regularly got my programs to compile. And so, I made my choice and went with C.

With that decision of C over Ada, a large portion of my development as a programmer was decided. I spent a ton of time in C dealing with code that segfaulted. The power and freedom that C gave me with pointers came back to bite me all the time. Sure, my code compiled but man, did it also crash a lot. I spent years with C and C++ learning patterns for sharing memory, for immutable objects, for concurrency via threading that I still use to this day; patterns to avoid dangerous code that the Ada compiler wouldn't let me write in the first place.

When I look back now at my Ada/C decision. I do so with some regret. I took the easy path. I let frustration get the best of me. And now whenever I encounter a difficult moment learning new languages like Haskell or Pony, I try to remember my Ada/C decision and stick will the language whose compiler is trying to tell me I'm doing it wrong. 
