#!/usr/local/bin/perl

use strict;
use warnings;

use Getopt::Long;

my $rc = GetOptions(
  "wordlist=s" => \ (my $wordlist = 'wordlist'),
  "all!"       => \  my $all,
);

$rc && @ARGV >= 2
  or die "usage: ladder [--wordlist=<wordlist>] [--all] ",
         "<word> <word> [<bad word> ...]\n";

my @word = splice @ARGV, 0, 2;

my @bad = @ARGV;

if (length $word[0] != length $word[1]) {
  die "Target words must be the same length.\n";
}

@bad = map { ($_, 0) } @bad;                 # for use in hash below

open(my $words_fh, '<', $wordlist) or die "Can't open $wordlist: $!\n";

my @wordlist;

while (<$words_fh>) {                            # load word list into memory
  chomp;
  push @wordlist, lc $_
    if length $_ == length $word[0];
}
close($words_fh);


my @queue = ([[$word[0]], 'break'], [[$word[1]], 'break']);
                                             # set up both halves of the queue

my @words = ({$word[0] => [], @bad}, {$word[1] => [], @bad});
                                             # set up both halves of
                                             #  the word path array

my @solutions;

my $p = 0;                                   # parity; which side of the
                                             #   ladder is being extended


# find a solution, advancing one side of the ladder and then the other

STEP:
while (1) {

  my $cur = shift @{$queue[$p]};

  if (not $cur) {                            # all paths are dead-ends;
    last;                                    #   give up
  }

  if ($cur eq 'break') {                     # no more paths to extend
    last if @solutions;                      # no more solutions at this length

    push @{$queue[$p]}, 'break' if @{$queue[$p]};

    if (@{$queue[$p^1]} <= @{$queue[$p]}) {
      $p ^= 1;                               # switch to other side of ladder
    }                                        #   if it has fewer steps

    redo;
  }

  my $top = $cur->[-1];

  my @step = find_step($top);                # find all possible steps
                                             #   from the current word

  my $step;
  foreach $step (@step) {
    if ($words[$p ^ 1]{$step}) {
      push @solutions, [@$cur, $step, reverse @{$words[$p ^ 1]{$step}}];
      last STEP unless $all;                 # stop unless looking for all
                                             #  solutions of this length
    }

    next if defined $words[$p]{$step};       # skip words already in path
                                             #   and bad words

    $words[$p]{$step} = [@$cur];             # add this word to path
        
    push @{$queue[$p]}, [@$cur, $step];      # put extended path on the queue

  }

}


foreach my $solution (@solutions) {          # for each solution found, if any
  if ($solution->[0] eq $word[1]) {          # print solution, in desired order
    $solution = [ reverse @$solution ];
  }
  print "$_\n" for @$solution;
  print "\n" if @solutions > 1;
}

if (not @solutions) {
  die "Can't find a solution for $word[0] - $word[1].\n";
}

exit 0;


# find_step($word)
# returns a list of all the words in the word list
#   that differ from $word by one character
sub find_step {
  my $word = shift;

  my $re;

  $re = '^(?:';

  $re .= join '|', map { substr(my $tmp = $word, $_, 1, '.'); $tmp }
                       0 .. length($word) - 1;
    
  $re .= ')$';

    
  $word =~ $re;                            # cache regex

  my @matches;

  for (@wordlist) {
    if (// and $_ ne $word) {
      push @matches, $_;
    }
  }

  return @matches;
}

__END__

=pod

=head1 NAME

B<ladder> -- find words which can be made from a string of letters

=head1 SYNOPSIS

B<ladder> [B<--wordlist>=I<wordlist>] [B<--all>] I<start-word> I<end-word>
       [I<bad-word> ...]

=head1 DESCRIPTION

B<ladder> solves word ladders.  A word ladder is a progression from
one word to another, changing exactly one letter per step.  Each
intermediate step must also be a word.  For example; dog cog cot cat.

Given the start word and the end word, B<ladder> will output a ladder
between the two words.  B<ladder> exits with an error if it is unable
to find a ladder within the maximum length.  The start and stop word
must be the same length.

A list of bad words may be specified after the other arguments.
B<ladder> will avoid using any of those words in the solution.

=head2 OPTIONS

B<ladder> accepts the following options:

=over 4

=item B<--wordlist>=I<wordlist>

By default, B<ladder> looks for a word file named 'wordlist' in the
same directory as the executable.  Use the B<-wordlist> option to
specify the path to an alternate word list.

=item B<--all>

By default, B<ladder> stops at the first solution it finds.  With
B<--all>, B<ladder> will continue to find all solutions of the same
length as the first.

=back

=head1 FILES

=over 4

=item F<wordlist>

The list of words, found with the executable.

For a comprehensive word list, the author recommends the ENABLE word
list, with more than 172,000 words, which can be found at
http://personal.riverusers.com/~thegrendel/software.html

=back

=head1 BUGS

This implementation of B<ladder> has no known bugs.

=head1 AUTHOR

B<ladder> was written by Ronald J Kimball, I<rjk-perl@tamias.net>.

=head1 COPYRIGHT and LICENSE

This program is copyright 2001-2004 by Ronald J Kimball.

This program is free and open software.  You may use, modify, or
distribute this program (and any modified variants) in any way you
wish, provided you do not restrict others from doing the same.

=cut
