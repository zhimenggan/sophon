#!/usr/bin/perl -w
use strict;

## compare the A,T,C,G percentage of the genome and putative HGT sequences

my ($genome,$kmer)= @ARGV;
die "Error with arguments!\nusage: $0 <Genome.fa> <K-mer>\n" if (@ARGV<2);

if($genome =~ /\.gz/){
    open(GENOME,"gzip -dc $genome|")||die("error");
}
else{
    open(GENOME,$genome)||die("error\n");
}

my %hash = ();
my @keys = ();
@keys = generateKmer($kmer,@keys);
foreach my $key(@keys){
    $hash{$key} = 0;
    print "$key\t$hash{$key}\n";
}

=pod
my ($genomeA,$genomeT,$genomeC,$genomeG) = (0,0,0,0);
while(<GENOME>){
    chomp();
    if($_ !~ />/){
	my $seq = $_;
	my $len = length($seq);
	for(my $i=0;$i<$len;$i++){
	    my $base = substr($seq,$i,1);
	    if($base eq 'A' || $base eq 'a'){
		$genomeA += 1;
	    }
	    elsif($base eq 'T' || $base eq 't'){
		$genomeT += 1;
	    }
	    elsif($base eq 'C' || $base eq 'c'){
		$genomeC += 1;
	    }
	    elsif($base eq 'G' || $base eq 'g'){
		$genomeG += 1;
	    }
	}
    }
}

my $all = $genomeA+$genomeT+$genomeC+$genomeG;
$genomeA = sprintf("%0.4f",$genomeA/$all);
$genomeT = sprintf("%0.4f",$genomeT/$all);
$genomeC = sprintf("%0.4f",$genomeC/$all);
$genomeG = sprintf("%0.4f",$genomeG/$all);
print "$genome\t$genomeA\t$genomeT\t$genomeC\t$genomeG\n";
=cut

sub generateKmer{
    my ($order,@previous) = @_;
    my @append = ();

    if(@previous eq ()){
	@append = ('A','T','C','G');
    }
    else{
	my @base = ('A','T','C','G');
	foreach my $item(@previous){
	    foreach my $char(@base){
		my $item2 = $item.$char;
		push(@append,$item2);
	    }
	}
    }

    $order -= 1;
    if($order == 0){
	return @append;
    }
    else{
	generateKmer($order,@append);
    }
}

sub GCpercentage{
    my ($seq) = @_;
    my ($A,$T,$C,$G) = (0,0,0,0);
    my $len = length($seq);
    for(my $i=0;$i<$len;$i++){
	my $base = substr($seq,$i,1);
	if($base eq 'A' || $base eq 'a'){
	    $A += 1;
	}
	elsif($base eq 'T' || $base eq 't'){
	    $T += 1;
	}
	elsif($base eq 'C' || $base eq 'c'){
	    $C += 1;
	}
	elsif($base eq 'G' || $base eq 'g'){
	    $G += 1;
	}
    }
    my $all = $A+$T+$C+$G;
    $A = sprintf("%0.2f",$A/$all);
    $T = sprintf("%0.2f",$T/$all);
    $C = sprintf("%0.2f",$C/$all);
    $G = sprintf("%0.2f",$G/$all);
    return ($A,$T,$C,$G);
}

close GENOME;
exit;