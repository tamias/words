#!/usr/local/bin/perl -w

# $Header: /usr/people/rjk/words/RCS/ladder.pl,v 1.5 2001/02/07 04:23:20 rjk Exp rjk $

use strict;

use vars qw($VERSION);
$VERSION = q$Revision: 1.5 $ =~ /Revision:\s*(\S*)/;

use Getopt::Std;

use vars qw($opt_w $opt_a);

if (not getopts('w:a') or @ARGV < 3 or $ARGV[2] =~ /\D/) {
    die <<EOT;
usage: $0 [-w <wordlist>] [-a] <word> <word> <max> [<bad word> ...]
EOT
}

my(@word, $max, @bad);

(@word[0, 1], $max, @bad) = @ARGV;

if (length $word[0] != length $word[1]) {
    die "Target words must be the same length.\n";
}

@bad = map { ($_, 0) } @bad;                 # for use in hash below

my $wordlist = $opt_w || 'wordlist';

open(WORDS, $wordlist) or die "Can't open $wordlist: $!\n";

my @wordlist;

while (<WORDS>) {                            # load word list into memory
    chomp;
    push @wordlist, $_
      if length $_ == length $word[0];
}
close(WORDS);


my @max = (int($max / 2) + ($max & 1), int($max / 2));
                                             # split $max in half;
                                             #   $max may be odd

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

    if (not $cur) {                          # all paths are dead-ends;
        last;                                #   give up
    }

    if ($cur eq 'break') {                   # no more paths to extend
        last if @solutions;                  # no more solutions at this length

        push @{$queue[$p]}, 'break' if @{$queue[$p]};
        $p ^= 1;                             # switch to other side of ladder
        redo;
    }

    my $top = $cur->[-1];

    my @step = find_step($top);              # find all possible steps
                                             #   from the current word

    my $step;
    foreach $step (@step) {
        if ($words[$p ^ 1]{$step}) {
            push @solutions, [@$cur, $step, reverse @{$words[$p ^ 1]{$step}}];
            last STEP unless $opt_a;         # stop unless looking for all
                                             #  solutions of this length
        }

        next if defined $words[$p]{$step};   # skip words already in path
                                             #   and bad words

        next if @{$cur} == $max[$p];         # skip if path is at max length

        $words[$p]{$step} = [@$cur];         # add this word to path
        
        push @{$queue[$p]}, [@$cur, $step];  # put extended path on the queue

    }

}


foreach my $solution (@solutions) {          # for each solution found, if any
    if ($solution->[0] eq $word[1]) {        # print solution, in desired order
        $solution = [ reverse @$solution ];
    }
    print "@$solution\n";
}

exit 0;


# find_step($word)
# returns a list of all the words in the word list
#   that differ from $word by one character
sub find_step {
    my $word = shift;

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

B<ladder> [B<-w> I<wordlist>] [B<-a>] I<start-word> I<end-word> I<max-length>
       [I<bad-word> ...]

=head1 DESCRIPTION

B<ladder> solves word ladders.  A word ladder is a progression from
one word to another, changing exactly one letter per step.  Each
intermediate step must also be a word.  For example; dog cog cot cat.

Given the start word, the end word, and the maximum allowed length,
B<ladder> will output a ladder between the two words.  B<ladder>
produces no output if it is unable to find a ladder within the maximum
length.  The start and stop word must be the same length.

A list of bad words may be specified after the other arguments.
B<ladder> will avoid using any of those words in the solution.

=head2 OPTIONS

B<ladder> accepts the following options:

=over 4

=item B<-w> I<wordlist>

By default, B<ladder> looks for a word file named 'wordlist' in the
same directory as the executable.  Use the B<-w> option to specify the
path to an alternate word list.

=item B<-a>

By default, B<ladder> stops at the first solution it finds.  With
B<-a>, B<ladder> will continue to find all solutions of the same
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

B<ladder> was written by Ronald J Kimball,
I<rjk@linguist.dartmouth.edu>.

=head1 COPYRIGHT and LICENSE

This program is copyright 2001 by Ronald J Kimball.

This program is free and open software.  You may use, modify, or
distribute this program (and any modified variants) in any way you
wish, provided you do not restrict others from doing the same.

=cut

