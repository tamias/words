#!/usr/local/bin/perl -w

# $Header: $

use strict;

if (@ARGV < 3 or $ARGV[2] =~ /\D/) {
    die "usage: $0 <word> <word> <max length> [<bad word> ...]\n";
}

my $max;

my @word;

my @bad;

($word[0], $word[1], $max, @bad) = @ARGV;

@bad = map {$_ => 0} @bad;

my $wordlist = 'wordlist';

open(WORDS, $wordlist) or die "Can't open $wordlist: $!\n";

my @words;
my @queue;


my @max = (int($max / 2) + ($max & 1), int($max / 2));

@queue = ([[$word[0]], 'break'], [[$word[1]], 'break']);
@words = ({$word[0] => [], @bad}, {$word[1] => [], @bad});

my @solution;

my $p = 0;
my $l = 1;

STEP:
while (1) {

    my $cur = shift @{$queue[$p]};

    if (not $cur) {
        last;
    }

    if ($cur eq 'break') {
        push @{$queue[$p]}, 'break' if @{$queue[$p]};
        $p ^= 1;
        redo;
    }

    my $top = $cur->[-1];

    my @step = find_step($top);

    my $step;
    foreach $step (@step) {
        if ($words[$p ^ 1]{$step}) {
            @solution = (@$cur, $step, reverse @{$words[$p ^ 1]{$step}});
            last STEP;
        }

        next if defined $words[$p]{$step};

        next if @{$cur} == $max[$p];

        $words[$p]{$step} = [@$cur];
        
        push @{$queue[$p]}, [@$cur, $step];

    }

}


if (@solution) {
    if ($solution[0] eq $word[1]) {
        @solution = reverse @solution;
    }
    print "@solution\n";
}


sub find_step {
    my $word = shift;

    seek(WORDS, 0, 0) or die "Can't seek in $wordlist: $!\n";

    my $l = length $word;

    my $re;

    $re = '^(?:';
    
    my $i;
    for ($i = 0; $i < length $word; ++$i) {
        my $tmp = $word;
        substr($tmp, $i, 1) = '.';
        $re .= $tmp . '|';
    }
    
    chop($re);
    
    $re .= ')$';

    
    $word =~ $re;

    my @matches;

    while (<WORDS>) {
        chomp;
        if (length $_ == $l and // and $_ ne $word) {
            push @matches, $_;
        }
    }
    
    return @matches;
}
