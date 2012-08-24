#!/usr/local/bin/perl -w

# find ladder orphans; words that cannot be changed into another word
# by changing a single letter

$length = shift || 4;

open(WORDS, "wordlist") or die "Can't open: $!\n";

WORD:
while (defined($word = <WORDS>)) {
  chomp $word;
  next WORD
    if length $word != $length;
  push @words, $word;
  for ($i=0; $i<length $word; ++$i) {
    $step = $word;
    substr($step, $i, 1) = '.';
    $steps{$step}++;
  }
}

close(WORDS);

$count = 0;

WORD:
foreach $word (@words) {
  next WORD
    if length $word != $length;
  for ($i=0; $i<length $word; ++$i) {
    $step = $word;
    substr($step, $i, 1) = '.';
    next WORD
      if $steps{$step} > 1;
  }
  $count++;
  print "$word\n";
}

print "$count orphans of length $length\n";
