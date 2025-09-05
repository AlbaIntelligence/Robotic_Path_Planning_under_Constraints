#!/bin/bash

for f in `ls *.txt`
do
    echo $f
    convert -page 2000x2000 -trim +repage -font Source-Code-Pro -pointsize 12 text:$f $f.png
done

# ffmpeg -r 10 -f image2  -i plan_printout_%04d.txt.png -vcodec libx264 test.mp4
