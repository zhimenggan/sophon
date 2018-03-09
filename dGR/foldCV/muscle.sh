#!/usr/bin/bash

i=$1
for ((c=1; c<=3; c ++))
do
    muscle -in group_$i/classify/classify_RT/class$c.fa -out tmp-$i-$c.txt
    chomp tmp-$i-$c.txt
    grep -v ">" tmp-$i-$c.txt >group_$i/align/RT-class$c.align
    rm tmp-$i-$c.txt
done