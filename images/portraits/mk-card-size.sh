#!/bin/bash

for i in $@; do echo $i; convert $i -resize 400x498 card-size/$i ; done
git add card-size/*.png
