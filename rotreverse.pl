#!/usr/local/bin/perl -w

# find words that can be rotated 13 letters and reversed to form another
# (or the same) word

use strict;

$| = 1;

my %words;
my @match;

while (<>) {
    chomp;
    $words{$_} = 1;
    my $rr = reverse $_;
    $rr =~ tr/a-zA-Z/n-za-mN-ZA-M/;
    push @match, "$rr $_" if $words{$rr};
}

print join "\n", (sort @match), '';

