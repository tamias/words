#!/usr/local/bin/perl -wln

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
