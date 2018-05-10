#!/bin/bash

if [ 1 == 2 ]  ###code annotation start
then

for i in `cat 53species.id`
do
    ./../axt2cov.pl cov/$i.cov /share/home/user/fzyan/hGT/data/data-wzhuang/vs$i/*.net.axt  #nohup 
    cat cov/$i.cov |sort -k1,1 -k2n,2 >cov/$i-sort.cov #nohup 
    rm cov/$i.cov
    
    '{if($9>=0.6){print $1"\t"$2"\t"$3}}' cov/$i-sort.cov >iden60/$i.bed
done

for i in `cat 12nonmammal.id`
do
    awk '{if($3-$2>=499){print $0}}' iden60/$i.bed >iden60/nonmammal-500bp/$i.bed
done

fi    ###code annotation end

chr=(chr1 chr10 chr11 chr12 chr13 chr14 chr15 chr16 chr17 chr18 chr19 chr2 chr20 chr21 chr22 chr3 chr4 chr5 chr6 chr7 chr8 chr9 chrX chrY)
for i in ${chr[@]}
do
    echo $i
    ./merge-nonmammal.pl chr_len.txt $i tmp-$i iden60/nonmammal-500bp/*bed
done

cat tmp-* |awk '{if($3-$2>=499){print $0}}' |sort -k1,1 -k2n,2 >iden60/nonmammal-500bp/merge-cov2-500bp.bed
