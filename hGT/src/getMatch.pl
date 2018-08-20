#!/usr/bin/perl -w
use strict;

my ($hit,$out)= @ARGV;
die "Error with arguments!\nusage: $0 <cov-unsorted results> <OUT File>\n" if (@ARGV<2);

# get the best LASTZ regions for a given hg38 region, in other species
# input : cov-unsorted results of species, generated by axt2cov.pl
#example:
#GCF_002113885.1_ASM211388v2_genomic 871 1000 NW_018473040.1 1 134 - 101 0.754
#GCF_002113885.1_ASM211388v2_genomic 893 1000 NW_018473040.1 1 85 - 68 0.630

open(HIT,$hit)||die("error\n");
open(OUT,">$out")||die("error\n");

my %hash = ();

while(<HIT>){
    chomp();
    my @arr = split(/\s+/,$_);
    my ($species,$chr,$start,$end,$identity) = ($arr[0],$arr[3],$arr[4],$arr[5],$arr[8]);
    my $len = (abs($end-$start)+1) * $identity;
    if(not exists($hash{$species})){
	$hash{$species} = $chr."-".$start."-".$end."-".$identity;
    }
    else{
	my $old = $hash{$species};
	my ($chr_old,$start_old,$end_old,$identity_old) = split(/-/,$old);
	if($len > (abs($end_old-$start_old)+1) * $identity_old){
	    $hash{$species} = $chr."-".$start."-".$end."-".$identity;
	}
    }
}

foreach my $key(keys %hash){
    my ($chr,$start,$end,$identity) = split(/-/,$hash{$key});
    print OUT "$key\t$chr\t$start\t$end\t$identity\n";
}

close HIT;close OUT;
exit;
