#!/usr/bin/perl -w
use strict;

#This script is used to reBuild the whole DGR structure,mainly used to search the TR-VR pair

my ($predict,$ref,$out,$summary,$NAratio,$miss)= @ARGV;
die "Error with arguments!\nusage: $0 <Result File In GTF Format> <Ref genome in FASTA format> <OUT File> <OUT summary file> <minNA ratio> <mutNA number>\n" if (@ARGV<6);

##default: $NAratio=0.5 (at least half of the bases are T/C/G)
##default: $miss=3 (at most three T/C/G mutation)

open(OUT,">$out")||die("Error with writing to $out\n");
open(SUMMARY,">$summary")||die("Error with writing to $summary\n");
open(REF,$ref)||die("Error with opening $ref\n");

print SUMMARY "id\tlength\texpand\tscore\tintegrity\tpair\n";

my %genome = ();
my ($name,$sequence) = ("","");
while(<REF>){
    chomp();
    if($_ =~ />([^\s]+)/){$name = $1;}
    elsif($_ =~ /[^\s]/){
	$sequence = $_;
	if(not exists($genome{$name})){$genome{$name} = $sequence;}
    }
    next;
}

my ($id,$seq,$start,$end,$dgr,$pair,$score,$len,$tmp) = ("","",0,0,"",0,0,0,"");
my @sub_seq=();
my @sub_start=();
my @sub_end=();
my @sub_string=();
my @type=();

open(FILE,$predict)||die("Error with opening $predict\n");
while(<FILE>){
    chomp();
    if($_ =~ /TR/){
	my @data = split(/\s+/,$_);
	push(@sub_seq,$data[6]);
	push(@sub_start,$data[4]);
	push(@sub_end,$data[5]);
	push(@sub_string,$data[3]);
	push(@type,1);
    }
    elsif($_ =~ /VR/){
        my @data = split(/\s+/,$_);
	push(@sub_seq,$data[6]);
        push(@sub_start,$data[4]);
        push(@sub_end,$data[5]);
	push(@sub_string,$data[3]);
        push(@type,2);
    }
    elsif($_ =~ /RT/){
        my @data = split(/\s+/,$_);
	push(@sub_seq,$data[6]);
        push(@sub_start,$data[4]);
        push(@sub_end,$data[5]);
	push(@sub_string,$data[3]);
        push(@type,3);
    }
    elsif($_ =~ /DGR/){
	my @data = split(/\s+/,$_);
	($start,$end,$score) = ($data[4],$data[5],$data[2]);
	$id = $data[0];
	$len = $end-$start+1;
        $seq = $genome{$id};
	
	if($seq ne ""){
	    my $index = 0;
	    for(my $i=0;$i<@sub_seq;$i++){
		if($type[$i] == 1){
		    my ($start_new,$end_new) = (-1,-1);
		    my $tmp_sub = "";
		    
		    my $NA = int(length($sub_seq[$i])*$NAratio);

		    if(numNA($sub_seq[$i]) >= $NA){
			($tmp_sub,$index,$start_new,$end_new)=searchVR($sub_seq[$i],$sub_start[$i],$sub_end[$i],$seq,$miss,$sub_string[$i],$id);
		    }
		    $tmp .= $tmp_sub;
		    $pair += $index;
		    if($start_new != -1 && $start_new < $start){
			$start = $start_new;
		    }
		    if($end_new > $end){$end=$end_new;}
		    
		}   
	    }
	    
	    if($pair != 0){
		$len = $end-$start+1;
		#$dgr = substr($seq,$start,$end-$start+1);
		print OUT "$id\tDGR\t*\t$start\t$end\t$len\n";
		print OUT "$tmp";
=pod
		for(my $i=0;$i<@sub_seq;$i++){
		    if($type[$i] == 3){
			print OUT "$id\tRT\t$sub_string[$i]\t$sub_start[$i]\t$sub_end[$i]\n";
		    }
		}
=cut
		my $len = length($dgr);
		print "$id\t$pair\n";
	    }
	    my $integrity = "incomplete";
	    my $expand = $end-$start+1;
	    if($pair != 0){$integrity = "complete";}
	    print SUMMARY "$id\t$len\t$expand\t$score\t$integrity\t$pair\n";
	}
	
	($id,$seq,$start,$end,$dgr,$pair,$score,$len,$tmp) = ("","",0,0,"",0,0,0,"");
	@sub_seq=();
	@sub_start=();
	@sub_end=();
	@sub_string=();
	@type=();
    }
    next;
}
close FILE;

sub searchVR{
    my ($TR,$start,$end,$seq,$miss,$string,$id)=@_;

    my $start_init = $start; #init start position of TR
    my $end_init = $end; #intit end position of TR

    my $tmp="";
    my $len = length($TR);

=pod
    if($miss > 0.1*$len){
        $miss = 0.1*$len;
    }
=cut
    
    my($result,$total_start,$total_end)=(0,$start,$end);

    my $seq2="";
    if($string eq '+'){
	$seq2=$seq;
    }
    else{
	$seq2 = myReverse($seq);
	my $num_tmp = $start;
	$start = length($seq2)-1-$end;
        $end = length($seq2)-1-$num_tmp;
    }
    
#search for positive string
    for(my $i=0;$i<length($seq)-length($TR);$i++){
	if(!($string eq '+' && $i==$start)){
	    my $index = 0;
	    my $substr = substr($seq,$i,length($TR));
	    
	    my $error = 0;
	    my $mut = 0;
	    
	    my $mutation = "";

	    for(my $j=0;$j<$len;$j++){
		my $char1 = substr($TR,$j,1);
		my $char2 = substr($substr,$j,1);
		if($char1 eq 'A' && $char1 ne $char2){
		    $mut++;
		}
		
		elsif($char1 ne 'A' && $char1 ne $char2 ){
		    $mutation .= "$char1-$char2;";
		    $error += 1;
		    if($error > $miss){
			$index = 1;
			last;
		    }
		}
	    }
	    
	    if($index == 0){ ## a VR founded,extention
		if($mutation ne ""){
		 ;#   print "mutation:$mutation\n";
		}
		my ($left,$right)=(1,1);
		for($left=1;$i-$left >= 0 && $start-$left >= 0;$left++){
		    my $char1 = substr($seq2,$start-$left,1); #TR
		    my $char2 = substr($seq,$i-$left,1); #VR
		    if($char1 eq 'A' && $char1 ne $char2){
			$mut++;
		    }
		    elsif($char1 ne 'A' && $char1 ne $char2){
			last;
		    }
		}
		for($right=1;$i+$len-1+$right < length($seq) && $end+$right < length($seq);$right++){
                    my $char1 = substr($seq2,$end+$right,1);
                    my $char2 = substr($seq,$i+$len-1+$right,1);
		    if($char1 eq 'A' && $char1 ne $char2){
                        $mut++;
                    }
                    elsif($char1 ne 'A' && $char1 ne $char2){
                        last;
                    }
                }
		$left -= 1;
		$right -= 1;
		
		my ($a,$b,$c,$d)=($start-$left,$end+$right,$i-$left,$i+$len-1+$right);
		my $TR_new = substr($seq2,$a,$b-$a+1);
                my $VR_new = substr($seq,$c,$d-$c+1);
		
		if($string eq '-'){
		    my $num_tmp = $a;
                    $a = length($seq2)-1-$b;
                    $b = length($seq2)-1-$num_tmp;
                }
		my $distance = abs($c-$a);
		print "distance:\t$distance\n";

		$tmp .= "$id\tTR\t$string\t$start_init\t$end_init\t$a\t$b\t$mut\t$error\t$TR_new\n";
		$tmp .= "$id\tVR\t+\t*\t*\t$c\t$d\t$mut\t$error\t$VR_new\n";
		$result +=1;
		if($a <= $total_start && $a <= $c){
		    $total_start = $a;
		}
		elsif($c<=$total_start){$total_start = $c;}
		
		if($b >= $total_end && $b >= $d){
                    $total_end = $b;
                }
                elsif($d>=$total_end){$total_end = $d;}
	    }
	}
    }

    
    #search for negative string
    my $seq1 = myReverse($seq);
    for(my $i=0;$i<length($seq1)-length($TR);$i++){
	if(!($string eq '-' && $i==$start)){
	    my $index = 0;
	    my $substr = substr($seq1,$i,length($TR));
	        
	    my $error = 0;
	    my $mut = 0;

	    my $mutation = "";

	    for(my $j=0;$j<$len;$j++){
		my $char1 = substr($TR,$j,1);
		my $char2 = substr($substr,$j,1);

		if($char1 eq 'A' && $char1 ne $char2 ){
		    $mut++;
		}
		elsif($char1 ne 'A' && $char1 ne $char2 ){
		    $mutation .= "$char1-$char2;";
		    $error += 1;
		    if($error > $miss){
			$index = 1;
			last;
		    }
		}
	    }
	        
	    if($index == 0){ ## a VR founded,extention
		if($mutation ne ""){
		    ;#print "mutation:$mutation\n";
		}
		my ($left,$right)=(1,1);
		for($left=1;$i-$left >= 0 && $start-$left >= 0;$left++){
		    my $char1 = substr($seq2,$start-$left,1); #TR
		    my $char2 = substr($seq1,$i-$left,1); #VR
		    if($char1 eq 'A' && $char1 ne $char2 ){
			$mut++;
		    }
		    elsif($char1 ne 'A' && $char1 ne $char2){
			last;
		    }
		}
		for($right=1;$i+$len-1+$right < length($seq) && $end+$right < length($seq);$right++){
                    my $char1 = substr($seq2,$end+$right,1);
                    my $char2 = substr($seq1,$i+$len-1+$right,1);
		    if($char1 eq 'A' && $char1 ne $char2 ){
			$mut++;
		    }
		    elsif($char1 ne 'A' && $char1 ne $char2){
                        last;
                    }
                }
		$left -= 1;
		$right -= 1;
		
		my ($a,$b,$c,$d)=($start-$left,$end+$right,$i-$left,$i+$len-1+$right);
		my $TR_new = substr($seq2,$a,$b-$a+1);
                my $VR_new = substr($seq1,$c,$d-$c+1);
		
		my $num_tmp = $c;
		$c = length($seq1)-1-$d;
		$d = length($seq1)-1-$num_tmp;

		if($string eq '-'){
		    $num_tmp = $a;
                    $a = length($seq2)-1-$b;
                    $b = length($seq2)-1-$num_tmp;
                }
		my $distance = abs($c-$a);
                print "distance:\t$distance\n";

		$tmp .= "$id\tTR\t$string\t$start_init\t$end_init\t$a\t$b\t$mut\t$error\t$TR_new\n";
		$tmp .= "$id\tVR\t-\t*\t*\t$c\t$d\t$mut\t$error\t$VR_new\n";
		$result +=1;
		if($a <= $total_start && $a <= $c){
		    $total_start = $a;
		}
		elsif($c<=$total_start){$total_start = $c;}
		
		if($b >= $total_end && $b >= $d){
                    $total_end = $b;
                }
                elsif($d>=$total_end){$total_end = $d;}
	    }
	}
    }

    return ($tmp,$result,$total_start,$total_end);
}

sub numNA{ #count the number of nucleotide notA
    my ($seq) = @_;
    my $num = 0;
    for(my $i=0;$i<length($seq);$i++){
	my $char = substr($seq,$i,1);
	if($char ne 'A'){
	    $num++;
	}
    }
    return $num;
}

sub myReverse{
    my ($seq) = @_;
    my $new="";
    for(my $i=length($seq)-1;$i>=0;$i--){
	my $char = substr($seq,$i,1);
	if($char eq 'A' || $char eq 'a'){$new .= 'T';}
	elsif($char eq 'T' || $char eq 't'){$new .= 'A';}
	elsif($char eq 'C' || $char eq 'c'){$new .= 'G';}
	elsif($char eq 'G' || $char eq 'g'){$new .= 'C';}
	else{
	    $new .= $char;
	}
    }
    return $new;
}

close OUT;close REF;
exit;