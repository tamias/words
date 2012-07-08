#!/usr/local/bin/perl

use strict;
use warnings;

my $dictionary = 'wordlist';

open my $dict_fh, '<', $dictionary
  or die "Can't open '$dictionary': $!\n";

my @words;
my %prefixes;

my $progress = 1;

my $width = 5;
my $height = 4;

while (<$dict_fh>) {
  chomp;

  my $len = length $_;

  $len == $width || $len == $height
    or next;

  push @{ $words[$len] }, $_;

  if ($len == $width) {
    for my $i (1 .. $len) {
      $prefixes{substr($_, 0, $i)} = 1;
    }
  }
}

our @prefixes = ('') x $height;
our @block;

step();

sub step {
  my ($word) = @_;

  local @block = @block;
  local @prefixes = @prefixes;

  if ($word) {
    push @block, $word;

    print "\r@block"
      if $progress;

    foreach my $i (0 .. length($word) - 1) {
      $prefixes[$i] .= substr($word, $i, 1);
    }

    foreach my $prefix (@prefixes) {
      $prefixes{$prefix}
        or return;
    }

    if (@block == $width) {
      # done!
      print "\r" if $progress;
      print "@block  @prefixes\n";
      return;
    }
  }

  foreach my $w (@{ $words[$height] }) {
    step($w);
  }
}
