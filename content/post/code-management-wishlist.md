+++
title = "Things I'd like in my code management tool"
author = "Sean T. Allen"
slug = "code-management-wishlist"
draft = false
date = "2018-12-26T13:31:27-05:00"
+++
This morning, I was reading a [blog post from Joe Armstrong](https://joearms.github.io/#2018-12-26%20Fun%20with%20the%20TiddlyWiki)  about how he got a [Chandler](https://en.wikipedia.org/wiki/Chandler_(software)) like [Triage system](https://en.wikipedia.org/wiki/Triage) working in [Tiddly-Wiki](https://tiddlywiki.com/). A Triage system is one of the things I'd like to see GitHub add. That got me thinking, what are some of the other things I'd like to see in a GitHub. What follows is far from a complete listing of some things that readily jumped to mind.

Most of what is on this list is in the area of "project management"; after all, code management is more than just about managing the code. It's about managing the project around the code.

## Multi-level issues

Most tools at best give me two levels. There's a project, and there are issues. Only having two levels can be hard to work with if you are interested in organizing work in a way that leads to better ["ambient awareness"](https://en.wikipedia.org/wiki/Ambient_awareness) of what is going on in a project. Having only two levels also makes a lot of the other "project management" features I mention later less attractive as well.

Ideally what I want is to start from something like "We are going to do X" and then break X down into issues and perhaps those issues into other issues.

At any time, I want to be able to look at any level and understand what is going on. Be it at the top level of the project or at any individual issue which might itself be a collection of issues.

Image an issue for example that is made up of 3 other issues. Each of those issues is assigned to different team members. When I look at my higher-level issue, I can see that 3 people are working on it. I can see there are 3 sub-issues that I can drill into. 

## Triage system
    
You can fake this with tags in something like GitHub, but it's a pain. For every issue, I want to be able to say it is for "now, later, or done." An issue can move from any state to any other state. See [https://en.wikipedia.org/wiki/Triage](https://en.wikipedia.org/wiki/Triage) for more information.

When something is marked as "later," I should be prompted in the future to reconsider it. "You said later for X, is it later yet? Should that become a now?"
    
## "Threaded" comments

 A popular GitHub issue is about as useful as a really popular IRC channel. Eventually, it devolves into several different conversations related to a general topic at once. It becomes increasingly hard to follow different threads of conversation. "Threading" is far from perfect but it's better than the "all in one long vertical bucket" that most tools supply.
        
## Dependencies between issues

Some tasks can't be started until others are finished. I want to be able to see and visualize this easily.

## Dependencies for issues

Sometimes some dependencies are outside the issue system itself. For example, only Alice is qualified to do this work at this time. We need Alice to be available. Alternatively, even, "either Alice or Bob could do this"

## Estimation of issues

Really, there are two styles of estimation that I'd like my tools to support. 

### High-level estimation
I want to be able to give quick, high-level estimates of things. For example- tiny, small, medium, large, huge that are a quick "we think it will take handwave amount of time." These are useful for getting a really rough idea of the amount of effort something would involve.

### Fine-grained estimation

I want to be able to apply estimates to that switch from a handwave amount of time to a granular estimate that is measured in days (it would be nice because some tasks are small to be able to measure in hours as well, but in the end, I could do without this).

## Attach "risk" to issues

Sometimes when we estimate an issue, we know with high certainty that our estimate is right. Other times, we know there's a great deal of possible variation. 

I address this by asking everyone to give a best case, worst case, and most likely case estimate for work. The wider the range between those estimates, the more risk there is and the less confidence we can have that the work won't end up derailing our project. Capturing this information on issues is valuable.

## Burndown charts

I want burndown charts that take into account dependencies and estimations. Burndown charts are a powerful way of visualizing if a project is on track or behind. 

In a burndown chart, I want to be able to run simulations as well. "What happens to this project if X work falls behind. What happens if Bob gets sick?"

You can do all the math yourself, but it's a hell of a lot nicer to have a computer do it for you (even if it can't account for nuance that you as a human can)

## Cumulative Flow Charts

I don't use them often, but they can be convenient from time to time for being able to visualize problems that might be ready to arise easily.

See [https://kanbantool.com/cumulative-flow-diagram](https://kanbantool.com/cumulative-flow-diagram) to learn more if you aren't familiar with them.

## Milestones 

I want milestones that are made up of various issues which will then be explicitly represented in burndown charts. I want a tool that can do the math I currently have to do to determine if something is "on track" or not. 

## Time tracking

Estimating is hard. We get it wrong all the time. However, we can't get it right if we aren't reflective on it. One way to do that is to record our original estimates for tasks and then record how much work we did on the item. Seeing that we thought something would take 8 hours of work but we spent 24 is incredibly valuable. We can revisit our assumptions we made when estimating see where we got it wrong. Then, we can try and account for it next time. Yes, estimating is hard but its also a skill you can get better at if you work at it and have support for proper tools.

## Ability to re-estimate

Look, sometimes we get those estimates wrong. Leaving the original estimate in place doesn't help. Then our dependencies and burndown charts are going to be wrong. I want the ability to change an estimate from 1 day to 10 days, and if work has already started, I want to be able to get access to earlier estimates and have the new estimate accounted for when determining if things are "on track", that means the new estimate should be reflected in milestones and burndown charts and every other style of information visualization that we might come up with.

## Estimate groups

Look, let's face it. If you have 3 different people and a single issue, it's quite likely that the amount of time it will take to complete that issue will vary based on who is doing it; sometimes it will vary greatly. 

You need to capture that information. It's essential for planning if it will take Alice 2 days to do something but 10 if Bob does it.

Estimation groups go back to an idea I expressed in "dependencies for issues." Sometimes, you have a limited number of people who can conceivably work on a particular problem.

## Due dates for "everything"

It's nice to be able to look at a thing and know "oh, this has to be done by Thursday for us to stay on track." 

## Kanban style board that is tied to changes in issue status

I want to be able to move things through a lifecycle that is displayed in a visual kanban style without doing a lot of manual moving of issues from one column to another.

## Issue status that is tied to Kanban style board

If I move an issue into an "in-progress" column in a board, that change should be reflected on the issue as well.

## Tie issues to "external" documents and vice-versa

When I estimate larger projects, I invariably end up working collaboratively with others in a GoogleDoc to come up with a project plan. A ton of information is captured in that doc:

- timelines
- dependencies
- assumptions
- in-depth detail

A lot of that information can be captured in other items I've put on my wishlist here, however, capturing the original information and tying it to the project is essential. I want to have a bidirectional link from a project and its issues to supporting documentation (there could be multiple documents). 

I want to be able to both edit those documents offline and in a collaborative fashion online.

I want to be able to comment on specific aspects of those docs as well and carry conversations in those comments.

## "Configurable" kanban board definition

Kanban boards are a great way to visualize things, but if I have to add everything to a board manually, it gets old fast. One of the great things about kanban boards is that they provide a visualization of information for a specific context. However, that context can vary. 

The ability to derive boards from a central pool of information would be great. In addition to "more traditional" boards, I might want to see on a per assignee basis, by estimate or god knows what. 

Even if I have only 1 board, not having to set everything up by hand would a godsend.

## Confidential "issues"

Some information shouldn't be made public. Perhaps it contains information about a security flaw or confidential information for a specific group that we are working it.

## Integrated "CI"

I love that GitHub has an API that allows me to hook up to tools like TravisCI, CircleCI, Code Climate, and what-not but, in the end, what I want is the ability to run arbitrary code at any point in a life cycle. That might be event-driven like, "on pull request, run these tasks," or it might be time-based "run fault injection tests daily with 50 random interleavings". Either way, I want that to be fully integrated into my "code management" tool. 

In the end, this is far more than just "CI." I want to be able to run "my code in my environment" on demand based on lifecycle events. Further, "my environment" probably means something more like "my containers" because I don't want to manage the infrastructure for all this.

[GitHub actions](https://github.com/features/actions) look intriguing and like a step in this direction. Perhaps they give me everything I would want but, I haven't played with them yet, so ¯\_(ツ)_/¯.

## File storage

I want to be able to store files of all sorts with my project — for example, dependencies like specific versions of a compiler. Alternatively, perhaps created artifacts and what not.

## Ability to "clone" everything

It's fantastic that tools like GitHub and Gitlab allow me to clone the code and work with it offline, but I want to be able to clone everything. Issues, project boards, wikis, everything! 

## Conclusion

Welp, that's where I got to with this morning's list. Now that I'm here, I realize there's a ton more for me dig into. For example, when I was putting this list together, I realized that I  need to do one that  is "what I want in an integrated CI system." There's a ton to dig into in just that topic. Moreover, there are a variety of others as well. For example, I gave zero thought to code review and that unto itself is yet another massive area. 

I think I'm going to start making lists for different areas like code management, code review, integrated CI and what not and slowly build up my list of "what I want in my code management tool" for real. I feel happy with this as a first pass.

Looking around, even though I'm a heavy [GitHub user](https://github.com/seantallen/), it looks like [Gitlab is the currently tool that would most likely end up fulfilling my desires](https://about.gitlab.com/features/). 

Got thoughts on things you'd like to see in a "GitHub like" tool? I'd love to hear them. Feel free to ping me on [Twitter](https://twitter.com/seantallen).


