#!/usr/local/bin/perl5 -w

use strict;

use File::Basename;

my($wordlist) = dirname($0) . "/wordlist";

if (@ARGV < 2) {
	warn "usage: $0 <min-length> <letters> ...\n";
	exit;
}

my($minlen) = shift @ARGV;               # minimum word length

if ($minlen =~ /\D/) {
	warn "$0: <min-length> must be a whole number\n";
	exit 1;
}

open(DICT, $wordlist) or                   # open word list
	die "Unable to open wordlist: $!";

my($letters);
foreach $letters (@ARGV) {               # for each letter sequence
	print "-- $letters --\n";

	my(%letters);

	$letters = lc $letters;              # convert to lowercase
	$letters =~ tr/a-z//cd;              # strip non-letter characters

	foreach (split(//, $letters)) {      # store letter counts
		$letters{$_}++;
	}

	seek(DICT, 0, 0);

	my($word);
  WORD:
	foreach $word (<DICT>) {             # for each word in list
		chomp($word);

		next if (length($word) < $minlen);
                                         # verify length
		next if ($word !~ /^[\Q$letters\E]+$/);
                                         # verify letters used

		my(%word);
		foreach (split(//, $word)) {     # verify letter counts
			$word{$_}++;
			next WORD if ($word{$_} > $letters{$_});
		}

		print "$word\n";                 # success - print word

	} # WORD: foreach $word (<DICT>)

	print "\n";

} # foreach $letters (ARGV)
