#!/usr/local/bin/perl -w

# demonstrate the bias that occurs when choosing a random word
# from a word list, by seeking to a random position in the file
# and then choosing the next word

use strict;

use IO::File;

my $count = 1_000_000;

my $file = shift or die "Must specify file\n";

my $fh = IO::File->new;

$fh->open($file) or die "Can't open $file: $!\n";

my $size = -s $file;

my %words;

for (1 .. $count) {
  $fh->seek(0, 0) or die "Can't seek in $file: $!\n";
  my $word = choose_word($fh, $size);

  $words{$word}++;
}

print_results();

print "\n";

%words = ();

$fh->seek(0, 0) or die "Can't seek in $file: $!\n";

my @words = <$fh>;
chomp @words;

for (1 .. $count) {
  $words{$words[int rand scalar @words]}++;
}

print_results();

sub choose_word {
  my($fh, $size) = @_;

  my $word;

  $fh->seek( int(rand($size)), 0 );  # pick a random spot in the file

  <$fh>;

  if (eof $fh) {
    $fh->seek(0, 0);
  }

  chomp( $word = <$fh> );

  return $word;

}

sub print_results {
  my @words = sort { $words{$b} <=> $words{$a} } keys %words;

  if (@words > 20) {
    @words = @words[0 .. 9, -10 .. -1];
  }

  for my $word (@words) {
    printf "%25s %5d\n", $word, $words{$word};
  }
}
