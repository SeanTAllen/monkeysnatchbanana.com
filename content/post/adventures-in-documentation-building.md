+++
draft = true
date = "2017-02-18T09:22:51-05:00"
title = "Adventures in Documentation Building"
tags = ["tag 1","tag 2"]
author = "Sean T. Allen"
slug = "adventures-in-documentation-building

+++

Does your project use [TravisCI](https://travis-ci.org)? Create it's documentation using [Mkdocs](http://www.mkdocs.org)? Awesome. Let me show you how to 

```
after_success:
  - if [[ $TRAVIS_BRANCH == 'master' && $TRAVIS_PULL_REQUEST == 'false' ]]; then
      git remote add gh-token "https://${GH_TOKEN}@github.com/${TRAVIS_REPO_SLUG}";
      git fetch gh-token && git fetch gh-token gh-pages:gh-pages;
      build/release/ponyc packages/stdlib --docs;
      cd stdlib-docs;
      sudo -H pip install mkdocs;
      mkdocs gh-deploy -v --clean --remote-name gh-token;
    fi;
```
