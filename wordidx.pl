#!/usr/local/bin/perl

use strict;

if (@ARGV < 2) {
	die "usage: $0 wordfile idxfile\n";
	exit 1;
}

my($wordfile, $idxfile) = @ARGV;

open(WORDS, $wordfile) or die "Unable to open $wordfile: $!\n";
open(IDX, ">$idxfile") or die "Unable to open $idxfile: $!\n";

my $offset = 0;
my $letter = '';

while(<WORDS>) {
	next if /^#/;
	if (substr($_, 0, 1) ne $letter) {
		$letter = substr($_, 0, 1);
		print IDX "$letter $offset\n";
	}
    $offset = tell(WORDS);
}

