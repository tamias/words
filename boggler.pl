#!/usr/local/bin/perl -w

# $Header: /usr/people/rjk/words/RCS/boggler.pl,v 1.3 2001/02/09 19:34:20 rjk Exp rjk $

use strict;

use vars qw($VERSION);
$VERSION = q$Revision: 1.3 $ =~ /Revision:\s*(\S*)/;

use Getopt::Std;

use vars qw($opt_w $opt_l $opt_d $opt_q);

if (not getopts('w:l:qd') or !@ARGV) {
    die <<EOT;
usage: $0 [-w <wordlist>] [-l <minlength>] [-q] <row> [<row> ...]
EOT
}

my $dict = $opt_w || 'wordlist';
my $DEBUG = $opt_d;

my $minlen = $opt_l || 3;

my $assume_qu = !$opt_q;

my $height = @ARGV;
my $width  = length $ARGV[0];

my $cubes = join '', @ARGV;
my @cubes;

$assume_qu = 0 unless $cubes =~ /q/;


# verify rows, create array of array of cubes

for (@ARGV) {
    if (length != $width) {
        die "All rows must be the same length.\n";
    }

    if (/[^a-zA-Z]/) {
        die "Each row must consist only of letters.\n";
    }

    push @cubes, [ split //, lc $_ ];
}


# create dictionary, as a dictionary tree

open(DICT, $dict) or die "Can't open $dict: $!\n";

my %dict;

while (<DICT>) {
    chomp;

    next if length $_ < $minlen;

    if ($assume_qu) {
        next if /q(?!u)/;
        s/qu/q/g;
    }

    next if /[^$cubes]/o;

    my @letters = split //;

    my $node = \%dict;

    for my $letter (@letters) {
        $node = $node->{$letter} ||= {};
    }
    $node->{_} = 1;
}
close(DICT);


# find and print words

for my $Y (0 .. $height - 1) {
    for my $X (0 .. $width - 1) {
        search($Y, $X, '', \%dict, '');
    }
}

exit;


# recursively find words from the specified cube

my %words;

use vars qw /$visited/;

INIT { $visited = ''; }

sub search {
    my($Y, $X, $letters, $dict) = @_;

    local($visited) = $visited;

    return if vec($visited, $Y * $width + $X, 1);

    vec($visited, $Y * $width + $X, 1) = 1;

    my $cube = $cubes[$Y][$X];

    $letters .= $cube;

    if (not $dict->{$cube}) {
        return;
    }

    warn ' ' x length($letters), "searching from ($Y, $X) with '$letters'\n"
      if $DEBUG;

    $dict = $dict->{$cube};


    # if a new word has been found, print it

    if ($dict->{_} and not $words{$letters}++) {
        my $word = $letters;

        $word =~ s/q/qu/g if $assume_qu;

        print "$word\n"
    }


    # recurse on surrounding cubes

    for my $y (-1, 0, 1) {

        my $newY = $Y + $y;
        next if $newY < 0 or $newY > $height - 1;

        for my $x (-1, 0, 1) {

            next if $y == 0 and $x == 0;

            my $newX = $X + $x;
            next if $newX < 0 or $newX > $width - 1;

            search($newY, $newX, $letters, $dict);
        }
    }

}

__END__

=pod

=head1 NAME

B<boggler> -- find words in a block of letters, in the manner of Boggle

=head1 SYNOPSIS

B<boggler> [B<-w> I<wordlist>] [B<-q>] I<row> [I<row> ...]

=head1 DESCRIPTION

B<boggler> finds words in a block of letters, in the manner of the
game Boggle from Parker Brothers.  A word is spelled out by joining
letters up, down, sideways, and diagonally, in a continuous path.
The same instance of a letter may not be used more than once in the
same word.

B<boggler> will print all words that can be spelled out with the
given block of letters.  Each row of letters in the block is passed
as a separate argument.  The standard block is four letters by four
letters, but B<boggler> will accept any rectangular block of
letters.

=head2 OPTIONS

B<boggler> accepts the following options:

=over 4

=item B<-w> I<wordlist>

By default, B<boggler> looks for a word file named 'wordlist' in the
same directory as the executable.  Use the B<-w> option to specify
the path to an alternate word list.

=item B<-l> I<minlength>

The minimum length of allowed words.  'qu' is always counted as two
letters, regardless of the B<-q> option.  Default for minimum length
is 3.

=item B<-q>

Normally, B<boggler> will assume the letter 'q' in the block of
letters represents 'qu'.  (The game Boggle has a cube printed 'Qu'.)
With the B<-q> option, B<boggler> will treat 'q' as 'q'.  Of course,
this makes the letter 'q' harder to use in a word.

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

B<boggler> has no known bugs.

=head1 AUTHOR

B<boggler> was written by Ronald J Kimball,
I<rjk@linguist.dartmouth.edu>.

=head1 COPYRIGHT and LICENSE

This program is copyright 2001 by Ronald J Kimball.

This program is free and open software.  You may use, modify, or
distribute this program (and any modified variants) in any way you
wish, provided you do not restrict others from doing the same.

=cut

