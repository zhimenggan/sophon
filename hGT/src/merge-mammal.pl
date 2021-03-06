#!/usr/bin/perl -w
use strict;

my ($file,$out)= @ARGV;
die "Error with arguments!\nusage: $0 <Mammal bed file> <OUT File>\n" if (@ARGV<2);

open(FILE,$file)||die("error with opening $file\n");
open(OUT,">$out")||die("error with writing to $out\n");

my @start = ();my @end = ();my $id = "";

while(<FILE>){
    chomp();
    my @arr = split(/\s+/,$_);
    if($id eq ""){
	$id = $arr[0];
	push(@start,$arr[1]);push(@end,$arr[2]);
    }
    else{
	if($arr[0] eq $id){
	    push(@start,$arr[1]);
	    push(@end,$arr[2]);
	}
	else{
	    print OUT "$id\t";
	    my $start_now = $start[0];my $end_now = $end[0];
	    for(my $i=1;$i<@start;$i++){
		if($start[$i] <= $end_now){
		    if($end[$i] > $end_now){
			$end_now = $end[$i];
		    }
		}
		else{
		    print OUT "$start_now-$end_now,";
		    $start_now = $start[$i];
		    $end_now = $end[$i];
		}
	    }
	    print OUT "$start_now-$end_now\n";
	    
	    $id = $arr[0];
	    @start = ();@end = ();
	    push(@start,$arr[1]);push(@end,$arr[2]);
	}
    }
}

print OUT "$id\t";
my $start_now = $start[0];
my $end_now = $end[0];
for(my $i=1;$i<@start;$i++){
    if($start[$i] <= $end_now){
	$end_now = $end[$i];
    }
    else{
	print OUT "$start_now-$end_now,";
	$start_now = $start[$i];
	$end_now = $end[$i];
    }
}
print OUT "$start_now-$end_now\n";

close FILE;close OUT;
exit;
