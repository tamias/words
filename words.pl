#!/usr/local/bin/perl5 -w

use strict;

use File::Basename;

my $dir = dirname($0);
my $wordlist = "$dir/wordlist";
my $wordidx  = "$dir/wordidx";

if (@ARGV < 2) {
	warn "usage: $0 <min-length> <letters> ...\n";
	exit;
}

my $minlen = shift @ARGV;                # minimum word length

if ($minlen =~ /\D/) {
	warn "$0: <min-length> must be a whole number\n";
	exit 1;
}

open(DICT, $wordlist) or                 # open word list
	die "Unable to open $wordlist: $!\n";

my($idx, %idx);
if (open(IDX, $wordidx)) {               # open word index
	while(<IDX>) {
		my($letter, $offset) = split;    # load letter/offset pairs
		$idx{$letter} = $offset;
		$idx = 1;                        # set index flag
	}
} else {
	warn "Unable to open $wordidx: $!\nProceeding without index.\n";
	$idx{0} = 0;
}

my $letters;
foreach $letters (@ARGV) {               # for each letter sequence
	print "-- $letters --\n";

	my %letters;

	$letters = lc $letters;              # convert to lowercase
	$letters =~ tr/a-z//cd;              # strip non-letter characters

	foreach (split(//, $letters)) {      # store letter counts
		$letters{$_}++;
	}

	my($letter, $word);
  IDX:
	foreach $letter ($idx ? sort keys %letters : 0) {
                                         # for each letter in
		                                 #   sequence if index loaded
		                                 #   (0) otherwise
		seek(DICT, $idx{$letter}, 0);    # seek to words beginning with letter

	  WORD:
		while (defined($word = <DICT>)) {
                                         # for each word in list
			next IDX if ($idx and substr($word, 0, 1) ne $letter);
                                         # next letter index if index loaded
			                             #   and done with current letter

			next if $word =~ /^#/;       # skip comments

			chomp($word);

			next if (length($word) < $minlen);
			                             # verify length
			next if ($word !~ /^[\Q$letters\E]+$/);
                                         # verify letters used

			my %word;
			foreach (split(//, $word)) { # verify letter counts
				$word{$_}++;
				next WORD if ($word{$_} > $letters{$_});
			}

			print "$word\n";             # success - print word

		} # WORD: while (defined($word = <DICT>))

	} # IDX: foreach $letter (sort keys %idx)

	print "\n";

} # foreach $letters (ARGV)
