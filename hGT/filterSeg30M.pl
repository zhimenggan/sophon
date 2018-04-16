#!/usr/bin/perl -w
use strict;

#This program is used to filter the fasta dataset accoring to the IDs matching to the ref sequences

my ($file1,$file2,$out)= @ARGV;
die "Error with arguments!\nusage: $0 <Reads.fa> <ID.txt> <OUT>\n" if (@ARGV<3);

open(OUT,">$out")||die("Can't write to $out\n");
open(SEQ,$file1)||die("Can't open $file1\n");
open(ID,$file2)||die("Can't open $file2\n");

my %id=();
while(<ID>){
    chomp($_);
    if(not exists $id{$_}){
	$id{$_} = 1;
    }
    next;
}

my $id="";
my $index = 0;
while(<SEQ>){
    chomp($_);
    if($_ =~ />/){
	if($_ =~ />([^\s]+)/){
	    $id = $1;
	}
	if(exists $id{$id}){
	    $index = 1;
	}
	else{
	    $index = 0;
	}
    }
    #elsif($index == 1){ #putout the sequence matchs
    elsif($index == 0){ #putout the sequence not matchs
	print OUT ">$id\n$_\n";
    }
    next;
}

close SEQ;close ID;close OUT;
exit;
