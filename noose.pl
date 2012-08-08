#!/usr/local/bin/perl

use strict;
use warnings;

use Getopt::Long;

$| = 1;

GetOptions(
  "wordlist=s" => \ (my $wordlist = 'wordlist'),
  "length=i"   => \ (my $length = 6),
  "guesses=i"  => \ (my $guesses = 20),
  "self!"      => \  my $self_play,
  "debug!"     => \  my $debug,
) or die "usage: noose [--wordlist=<wordlist>] [--length=<length>] ",
         "[--guesses=<guesses>] [--self] [--debug]\n";

open(my $dict_fh, '<', $wordlist) or die "Can't open $wordlist: $!\n";

my @words;

while (<$dict_fh>) {
  chomp;

  next if $_ =~ /[^a-z]/;
  push @words, $_ if length $_ == $length;
}

if (not @words) {
  die "No words!\n";
}

my @letters = ('_') x $length;

my %unguessed = map {$_ => 1} 'a' .. 'z';
my %guessed;

while (keys %guessed < $guesses and "@letters" =~ /_/) {
  print "\n";

  debug(scalar(@words), " possible word(s).");
  debug(join(', ', @words))
    if @words <= 10;

  print "@letters\nGuessed: ", sort(keys %guessed), "\n";

  print "? ";
  my $guess;

  if ($self_play) {
    sleep 1;
  }

  if ($self_play) {
    $guess = (keys %unguessed)[rand keys %unguessed];
    print "$guess\n";
    delete $unguessed{$guess};
  } else {
    $guess = lc <STDIN>;
    chomp $guess;
  }

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

print "\n";

debug(scalar(@words), " possible word(s).");
debug(' ' . join(', ', @words))
  if @words <= 10;

print "@letters\nGuessed: ", sort(keys %guessed), "\n";

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

sub debug {
  print STDERR "debug: ", @_, "\n"
    if $debug;
}
