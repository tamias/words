#!/usr/local/bin/perl -wn

# $Header: $

use strict;

my $re;

INIT {
    
    my $word = shift or die "No word.\n";
    
    if ($word =~ /[^a-z]/) {
        die "Word must consist only of lowercase letters.\n";
    }
    
    $re = '^(?:';
    
    my $i;
    for ($i = 0; $i < length $word; ++$i) {
        my $tmp = $word;
        substr($tmp, $i, 1) = '.';
        $re .= $tmp . '|';
    }
    
    chop($re);
    
    $re .= ')$';

    @ARGV = 'wordlist';

}


print if /$re/o;
