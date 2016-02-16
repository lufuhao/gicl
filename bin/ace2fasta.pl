#!/usr/bin/env perl
use strict;
use Getopt::Std;
use constant USAGE =><<EOH;

Usage:
 ace2fasta.pl -o <output.contigs_fasta> [-c <output.components_file>] <input.acefile>

v20160216

EOH
umask 0002;
getopts('o:c:') || die($usage."\n");
my $outfile=$Getopt::Std::opt_o || die("$usage\nMust specify output file name!\n");
open(CFASTA, '>'.$outfile) || die ("Error: creating file $outfile!\n");
my $lnkfile=$Getopt::Std::opt_c;
if (defined $lnkfile ans -s $lnkfile) {
	open(COMP, '>'.$lnkfile) || die ("Error: creating file $lnkfile!\n");
}

my $ctg; #current contig
my $ctgseq; #current contig sequence
my $ctglen; #current contig seq length
my $numseqs;
my @ctgcomp; #list of component sequence names
my %seqs; # seq => [ seqlen, strand, seqL, seqR, asmL, asmR ]

while (<>) {
	if (m/^CO (\S+) (\d+) (\d+)/) {
		my ($c, $l, $n)=($1, $2, $3);
		if ($c ne $ctg) {
			&writeCtg() if $ctg;
			undef %seqs;
			undef @ctgcomp;
			($ctg, $ctglen, $numseqs)=($c, $l, $n);
		}
		$ctgseq='';
		my $seqline;
		while (<>) {
			($seqline)=(/^(\S+)/);
			last unless $seqline;
			$ctgseq.=$seqline;
		}
	} #contig start line
	elsif (m/^AF (\S+) ([UC]) ([\-\d]+)/) {
		my $strand=($2 eq 'U')?'+':'-';
		$seqs{$1}=[0, $strand, 0, 0, $3, 0]; #the untrimmed asmL position for now
	}
	elsif (m/^RD (\S+) (\d+) (\d+) (\d+)/) {
		my ($seqname, $seqlen)=($1, $2);
		my $seqd=$seqs{$seqname};
		push(@ctgcomp, $seqname);
		die("Error at ACE parsing: no sequence found for RD $seqname\n") unless $seqd;
		$seqd->[0]=$seqlen;
		my $rdseq='';
		my $seqline;
		while (defined($_=<>) && (($seqline)=(/(\S+)/))) {
			$rdseq.=$seqline;
		}
		do {
			$_=<>;
		} until m/^QA (\d+) (\d+)/ || !defined($_);
		die("Error: Couldn't find the QA entry for RD $seqname!\n") unless defined($_);
		($seqd->[2], $seqd->[3]) = ($1, $2);
		my ($trimL, $trimR)=($seqd->[2]-1, $seqlen-$seqd->[3]);
		$seqd->[5]=$seqd->[4]+$seqlen-$trimR-1;
		$seqd->[4]+=$trimL;
	}
}

writeCtg() if $ctg;

close(CFASTA);
close(COMP) if $lnkfile;


#####################################################################
#####################  sub functions  ###############################
#####################################################################


sub writeCtg {
	print CFASTA ">$ctg $numseqs\n";
	for (my $p=0;$p<length($ctgseq);$p+=60) {
		print CFASTA substr($ctgseq, $p, 60)."\n";
		}
	if ($lnkfile) {
		print COMP ">$ctg $numseqs $ctglen\n";
		foreach my $seqname (@ctgcomp) {
			my $sd=$seqs{$seqname} || 
			die("Error: no seqdata for component $seqname!\n");
			print COMP $seqname.' '.join(' ',@$sd)."\n";
		}
	}
}
