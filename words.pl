#!/usr/local/bin/perl5 -w

# $Header: /people2/rjk/words/RCS/words.pl,v 1.5 98/06/16 22:54:05 rjk Exp Locker: rjk $

use strict;

use File::Basename;

use Getopt::Std;

use vars qw($opt_w);

getopts('w:') || die "Bad options.\n";

my $dir = dirname($0);
my $wordlist = $opt_w || "$dir/wordlist";
my $wordidx  = "$wordlist.idx";

if (@ARGV < 2) {
    warn "usage: $0 <min-length> <letters> ...\n";
    exit;
}

my $minlen = shift @ARGV;                # minimum word length

if ($minlen =~ /\D/) {
    die "$0: <min-length> must be a whole number\n";
}

open(DICT, $wordlist) or                 # open word list
    die "Unable to open $wordlist: $!\n";

my($idx, %idx);

if (!-e $wordidx) {
    warn "Unable to locate $wordidx.\n";
} elsif (-M $wordlist < -M $wordidx) {
    warn "$wordlist is newer than $wordidx.\n";
} elsif (! open(IDX, $wordidx)) {
    warn "Unable to open $wordidx: $!\n";
} else {
    $idx = 1;                            # set index flag
    while(<IDX>) {
        my($letter, $offset) = split;    # load letter/offset pairs
        $idx{$letter} = $offset;
    }
}

if (! $idx) {
    warn "Proceeding without index.\n";
    $idx{0} = 0;
}

$| = 1;

my $letters;
foreach $letters (@ARGV) {               # for each letter sequence
    my $words = 0;

    print "-- $letters --\n";

    my %letters;

    $letters = lc $letters;              # convert to lowercase
    $letters =~ tr/a-z//cd;              # strip non-letter characters

    foreach (split(//, $letters)) {      # store letter counts
        $letters{$_}++;
    }

    "\0" =~ /[^$letters]/;               # cache regex with successful match

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

            chomp($word);

            next WORD if (length($word) < $minlen);
                                         # verify length
            next WORD if ($word =~ //);
                                         # verify letters used,
                                         #  using cached regex
                                         # comments also skipped here

            my %word;
            foreach (split(//, $word)) { # verify letter counts
                $word{$_}++;
                next WORD if ($word{$_} > $letters{$_});
            }

            print "$word\n";             # success - print word
            $words++;

        } # WORD: while (defined($word = <DICT>))

    } # IDX: foreach $letter (sort keys %idx)

    print "$words\n\n";

} # foreach $letters (ARGV)
