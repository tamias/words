#!/usr/local/bin/perl

# $Header: /usr/people/rjk/words/RCS/wordidx.pl,v 1.3 2000/12/10 23:30:37 rjk Exp rjk $

use strict;

if (@ARGV != 2) {
	die "usage: wordidx <input file> <output file>\n";
}

my($wordfile, $idxfile) = @ARGV;

open(WORDS, $wordfile) or die "Unable to open $wordfile: $!\n";
open(IDX, ">$idxfile") or die "Unable to open $idxfile: $!\n";

my $offset = 0;
my $letter = '';

my %letters;

while(<WORDS>) {
	next if /^#/;

	if (substr($_, 0, 1) ne $letter) {
		$letter = substr($_, 0, 1);

        if ($letters{$letter}) {
          close(IDX);
          unlink $idxfile;

          die "Words beginning with $letter start on lines " .
              "$letters{$letter} and $. of $wordfile.\n";
        }

        $letters{$letter} = $.;

		print IDX "$letter $offset\n";
	}

    $offset = tell(WORDS);
}

__END__

=pod

=head1 NAME

B<wordidx> -- create an index file for a sorted word list

=head1 SYNOPSIS

B<wordidx> I<input-file> I<output-file>

=head1 DESCRIPTION

B<wordidx> creates an index file for a sorted word list file.  Each
line in the index consists of a letter, a space, and the byte offset
into the word list file of the first word beginning with that letter.

If the resulting index file is to be used with the L<words|words>
program, it should have the same name as the word list file, with .idx
appended.

=head1 SEE ALSO

L<words|words>

=head1 BUGS

B<wordidx> has no known bugs.

=head1 AUTHOR

B<words> was written by Ronald J Kimball, I<rjk-perl@tamias.net>.

=head1 COPYRIGHT and LICENSE

This program is copyright 2000 by Ronald J Kimball.

This program is free and open software.  You may use, modify, or
distribute this program (and any modified variants) in any way you
wish, provided you do not restrict others from doing the same.

=cut

