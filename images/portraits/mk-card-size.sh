#!/bin/bash

#used to be 400x498
for i in $@; do echo $i; convert $i -resize 480x420 card-size/$i ; done
git add card-size/*.png
