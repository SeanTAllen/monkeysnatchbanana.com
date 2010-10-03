#!/bin/bash

cd jekyll
jekyll build/ && rsync -v -r -c --exclude .DS_Store --delete build/* msb:/home/public/ && rm -rf build/
