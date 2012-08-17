#!/usr/local/bin/perl

# find groups of anagrams at the specified word length
# prints the largest groups found

use strict;
use warnings;

use File::Basename;
use Getopt::Long;

my $rc = GetOptions(
  "wordlist=s" => \ (my $wordlist = 'wordlist'),
);

$rc && @ARGV == 1
  or die "usage: anamax [--wordlist <wordlist>] <length>\n";

my $length = shift @ARGV;

if ($length =~ /\D/) {
  die "<length> must be a whole number\n";
}

open(my $words_fh, '<', $wordlist) or die "Can't open $wordlist: $!\n";

my %count;

while (<$words_fh>) {
  chomp;
  next if length != $length;

  my $canon = join '', sort split //;

  push @{$count{$canon}}, $_;
}

close $words_fh;

print scalar(keys %count), " groups.\n";

my $i;
my $limit = 2;
for (sort { @{$count{$b}} <=> @{$count{$a}} ||
            $count{$a}[0] cmp $count{$b}[0] } keys %count) {
  last if @{$count{$_}} < $limit;
  if ($limit == 2 and $i++ > 10) {
    $limit = @{$count{$_}};
  }
  print "@{$count{$_}}\n";
}
