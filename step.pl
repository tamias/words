#!/usr/local/bin/perl -wln

# $Header: /usr/people/rjk/words/RCS/step.pl,v 1.1 2000/04/22 02:58:19 rjk Exp rjk $

use strict;

use vars qw/$word/;

INIT {
    
    $word = shift or die "No word.\n";
    
    if ($word =~ /[^a-z]/) {
        die "Word must consist only of lowercase letters.\n";
    }
    
    @ARGV = 'wordlist';

}

next if length $_ != length $word;
my $tmp = $word ^ $_;
print if 1 == $tmp =~ tr/\0//c;
