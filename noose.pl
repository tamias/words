#!/usr/local/bin/perl -w

use strict;
use Getopt::Std;

use vars qw($opt_w $opt_l $opt_g);

getopts('w:l:g:') || die "Bad options.\n";

my $dict = $opt_w || 'wordlist';

open(DICT, $dict) or die "Can't open $dict: $!\n";

my $length = $opt_l || 6;

my $guesses = $opt_g || 20;

my @words;

while (<DICT>) {
  chomp;

  next if $_ =~ /[^a-z]/;
  push @words, $_ if length $_ == $length;
}

if (not @words) {
  die "No words!\n";
}

my @letters = ('_') x $length;

my %guessed;

while (keys %guessed < $guesses and "@letters" =~ /_/) {
  print "\n@letters\nGuessed: ", sort(keys %guessed), "\n? ";

  my $guess = lc <STDIN>;
  chomp $guess;

  redo if length $guess > 1;
  $guess = lc $guess;
  redo if $guess =~ /[^a-z]/;

  redo if exists $guessed{$guess};

  $guessed{$guess} = 1;

  my $p = partition_words($guess);

  if ($p == @words) {
    my $word = $words[rand @words];

    for (my $i = 0; $i < length $word; ++$i) {
      if (substr($word, $i, 1) eq $guess) {
        $letters[$i] = $guess;
      }
    }

    $word =~ s/[^$guess]/[^$guess]/g;

    my $q = partition_words($word);

    splice(@words, $q);
  } else {
    splice(@words, 0, $p);
  }
}

if ("@letters" =~ /_/) {
  print "\nOh no!\n";
} else {
  print "\n", @letters, "!\n";
}

exit;

sub partition_words {
  my($pattern) = @_;

  $pattern = qr/$pattern/;

  my($p, $q);

  for ($p = $q = 0; $q < @words; ++$q) {
    if ($words[$q] =~ $pattern) {
      @words[$p, $q] = @words[$q, $p]
        unless $p == $q;
      $p++;
    }
  }

  $p;
}
