#!/usr/local/bin/perl

# find ladder orphans; words that cannot be changed into another word
# by changing a single letter

use strict;
use warnings;

my $length = shift || 4;

open(my $words_fh, "<", "wordlist") or die "Can't open: $!\n";

my (@words, %steps);

WORD:
while (my $word = <$words_fh>) {
  chomp $word;
  next WORD
    if length $word != $length;
  push @words, $word;
  for (my $i=0; $i<length $word; ++$i) {
    my $step = $word;
    substr($step, $i, 1) = '.';
    $steps{$step}++;
  }
}

close($words_fh);

my $count = 0;

WORD:
foreach my $word (@words) {
  next WORD
    if length $word != $length;
  for (my $i=0; $i<length $word; ++$i) {
    my $step = $word;
    substr($step, $i, 1) = '.';
    next WORD
      if $steps{$step} > 1;
  }
  $count++;
  print "$word\n";
}

print "$count orphans of length $length\n";
