#!/usr/local/bin/perl -w

# find groups of anagrams at the specified word length
# prints the largest groups found

use strict;

use File::Basename;

use Getopt::Std;

use vars qw($opt_w);

getopts('w:') || die "Bad options.\n";

my $dir = dirname($0);
my $wordlist = $opt_w || "$dir/wordlist";

if (@ARGV < 1) {
    warn "usage: $0 <length>\n";
    exit;
}

my $length = shift @ARGV;

if ($length =~ /\D/) {
    die "$0: <length> must be a whole number\n";
}

open(DICT, $wordlist) or                 # open word list
    die "Unable to open $wordlist: $!\n";

my %count;

while (<DICT>) {
    chomp;
    next if length != $length;

    my $canon = join '', sort split //;

    push @{$count{$canon}}, $_;
}

close DICT;

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
