#!/bin/bash

if [ 1 == 2 ]  ###code annotation start
then

###############
# iden60len40 #
###############

for i in `cat 53species.id`
do
    ./../axt2cov.pl cov/$i.cov /share/home/user/fzyan/hGT/data/data-wzhuang/vs$i/*.net.axt  #nohup 
    cat cov/$i.cov |sort -k1,1 -k2n,2 >cov/$i-sort.cov #nohup 
    rm cov/$i.cov
    
    awk '{if($9>=0.6){print $1"\t"$2"\t"$3}}' cov/$i-sort.cov >iden60/$i.bed
done

for i in `cat 12nonmammal.id`
do
    #awk '{if($3-$2>=999){print $0}}' iden60/$i.bed >iden60/nonmammal-1kbp/$i.bed
    cp iden60/$i.bed iden60/nonmammal/$i.bed
done

chr=(chr1 chr10 chr11 chr12 chr13 chr14 chr15 chr16 chr17 chr18 chr19 chr2 chr20 chr21 chr22 chr3 chr4 chr5 chr6 chr7 chr8 chr9 chrX chrY)
for i in ${chr[@]}
do
    echo $i
    ./merge-nonmammal.pl chr_len.txt $i tmp-$i iden60/nonmammal/*bed
done

cat tmp-* |sort -k1,1 -k2n,2 >iden60/nonmammal/merge-cov2-1kbp.bed
rm tmp-*

for id in `cat 41mammal.id`
do
    ./../src/merge-mammal.pl iden60/$id.bed iden60/mammal/$id-merged.txt
    
    nohup ./../src/screenHGT.pl iden60/nonmammal/merge-cov2-1kbp.bed tmp-$id 0.4 iden60/mammal/$id-merged.txt &
done

./summaryMammal.pl iden60/nonmammal/merge-cov2-1kbp.bed  iden60/nonmammal/screenHGT.out tmp-*
rm tmp* 

###############
# iden40len20 #
###############

for i in `cat 53species.id`
do
    awk '{if($9>=0.4){print $1"\t"$2"\t"$3}}' cov/$i-sort.cov >iden40/$i.bed
done

for i in `cat 12nonmammal.id`
do
    mkdir iden40/nonmammal
    cp iden40/$i.bed iden40/nonmammal/$i.bed
done

chr=(chr1 chr10 chr11 chr12 chr13 chr14 chr15 chr16 chr17 chr18 chr19 chr2 chr20 chr21 chr22 chr3 chr4 chr5 chr6 chr7 chr8 chr9 chrX chrY)
for i in ${chr[@]}
do
    nohup ./merge-nonmammal.pl chr_len.txt $i tmp-$i 1000 iden40/nonmammal/*bed &
done

cat tmp-* |sort -k1,1 -k2n,2 >iden40/nonmammal/merge-cov2-1kbp.bed
rm tmp-*

mkdir iden40/mammal

for id in `cat 41mammal.id`
do
    #./../src/merge-mammal.pl iden40/$id.bed iden40/mammal/$id-merged.txt
    nohup ./../src/screenHGT.pl iden40/nonmammal/merge-cov2-1kbp.bed tmp-$id 0.2 iden40/mammal/$id-merged.txt &
done

./summaryMammal.pl iden40/nonmammal/merge-cov2-1kbp.bed iden40/nonmammal/screenHGT.out tmp-*
rm tmp*

awk '{if($4<=8){print $0}}' iden40/nonmammal/screenHGT.out |sort -k1,1 -k2n,2 >iden40/nonmammal/screenHGT-8mammal.bed

fi    ###code annotation end


blastn -query screenHGT-8mammals.fa -db ~/hGT/db/hg19 -out screenHGT-8mammals-hg19.blastn -evalue 1e-3 -num_threads 20 -outfmt 7 -word_size 7

./../blast/filterHits.pl screenHGT-8mammals-hg19.blastn

for i in hit/*.txt
do
    pre=${i%.txt}
    cat $i |sort -k1,1 -k2n,2 >$pre.sort.txt
    ~/hGT/compare2lastz/mergeBed.pl $pre.sort.txt $pre.merge.txt
    rm $pre.sort.txt
done