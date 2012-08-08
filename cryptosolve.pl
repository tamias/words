#!/usr/local/bin/perl

use strict;
use warnings;

use Getopt::Long qw/ :config require_order /;

$| = 1;

GetOptions(
  "wordlist=s" => \ (my $dict = 'wordlist'),
  "upper!"     => \  my $force_upper,
  "debug!"     => \  my $DEBUG,
  "once!"      => \  my $ELIMINATE_ONCE,
) or exit 1;

open(DICT, $dict) or die "Can't open $dict: $!\n";

my @crypto;
if (@ARGV) {
  @crypto = @ARGV;
} else {
  local $/;
  @crypto = split ' ', <>;
}

if ($force_upper) {
  $_ = uc $_ for @crypto;
}


# save original text for translation at the end

my $crypto = "@crypto";

print "$crypto\n";


# remove obviously unimportant puncuation
# keep only translatable words
#   (e.g. word list does not contain contractions)
# keep only unique words

my %seen;
@crypto = grep { s/^"//; s/[,.";!?]+$//;
                 /^[a-zA-Z]+$/ and !$seen{$_}++ } @crypto;

print "@crypto\n";


# create a regex for each base word that matches real words
# with the same cryptographic pattern

my @regex = map scalar(crypto_regex($_)), @crypto;


# assume one-letter words will translate to 'a' or 'I'
# (word list may not contain 'a' or 'i')

my @words = map [ length == 1 ? ('a', 'i') : () ], @crypto;


# build an array of arrays of all the matching real words
# for each base word

while (<DICT>) {
  chomp;

  next if length == 1;
  next if /[^a-z]/;
    
  my $crypt;

  for my $i (0 .. $#crypto) {
    next unless length $crypto[$i] == length $_;
    next unless /$regex[$i]/;

    push @{$words[$i]}, $_;
  }
}



# count the number of real words for each crypto word,
# and make sure each base word has at least one real word

my $total = 0;

my @no_words;

for my $i (0 .. $#crypto) {
  my $c = @{ $words[$i] };
    
  if (not $c) {
    push @no_words, $crypto[$i];
  }
    
  $total += $c;
  print "$c " if $DEBUG;
}

print "\n" if $DEBUG;

if (@no_words) {
  die "No possible word matches for @no_words.\n";
}



# calculate the set of translations for each letter
# eliminate conflicting translations
# repeat until no more translations can be eliminated

my $last_total = 0;

my %trans;

while ($total != $last_total) {

  print join(' ', map $_->[0], @words), "\n" if $DEBUG;

  # get the set of translations for the letters in the first base word

  %trans = %{ make_trans($crypto[0], $words[0]) };

  for my $i (1 .. $#crypto) {

    # get the set of translations for the letters in the next base word

    my $tmp = make_trans($crypto[$i], $words[$i]);

    # for each base letter, eliminate translations from previous
    # base words which aren't possible with the current base word
    # e.g. if previous words yielded X => A,B
    #      and the current word yields X => B,C
    #      the result is X => B

    foreach my $base (keys %$tmp) {
      if (not $trans{$base}) {
        $trans{$base} = $tmp->{$base};
        next;
      }
      foreach my $sol (keys %{$trans{$base}}) {
        delete $trans{$base}{$sol}
          unless $tmp->{$base}{$sol};
      }
    }
  }


  # for each base letter which now has only one possible translation
  # eliminate that translation from all other bases

  my %definite = ();

  foreach my $base (sort { keys %{$trans{$a}} <=> keys %{$trans{$b}} }
                         keys %trans) {
    my @keys = keys %{$trans{$base}};
    if (@keys == 1 and not exists $definite{$keys[0]}) {
      $definite{$keys[0]} = 1;
    } elsif (keys %definite) {
      my @del = delete @{$trans{$base}}{keys %definite};
      redo if grep $_, @del;
    }
  }


  # create a character classes for each base letter
  # make sure each base letter has at least one translation

  my @no_trans;

  my %classes;

  foreach my $base (sort keys %trans) {
    if (not %{$trans{$base}}) {
      push @no_trans, $base;
    }

    $classes{$base} = '[' . join('', sort keys %{$trans{$base}}) . ']';
    print "$base $classes{$base}\n" if $DEBUG;
  }

  if (@no_trans) {
    die "No possible translations for @no_trans.\n";
  }


  # eliminate words which are no longer possible with the new set of
  # translations

  for my $i (0 .. $#crypto) {
    eliminate_words($crypto[$i], $words[$i], \%classes);
  }


  # count the new number of real words for each base word
  # make sure each base word has at least one real word still

  $last_total = $total;
  $total = 0;

  my @no_words;

  for my $i (0 .. $#crypto) {
    my $c = @{ $words[$i] };

    if (not $c) {
      push @no_words, $crypto[$i];
    }

    $total += $c;
    print "$c " if $DEBUG;
  }

  print "\n" if $DEBUG;

  if (@no_words) {
    die "No remaining word matches for @no_words.\n";
  }

  last if $ELIMINATE_ONCE;

}


# find the solution(s)!

my @solutions;

if (0) {

  # old approach
  # try translations one base word at a time
  # redundant when several real words share a letter
  # e.g. XYZ => cat, cow, dog tries X => C twice
  #      even when X => C is incorrect

  # try base words in ascending order by number of real words

  my @order = sort { @{$words[$a]} <=> @{$words[$b]} ||
                     length $crypto[$b] <=> length $crypto[$a]
                   } 0 .. $#words;

  @solutions = try({}, \@order);

  for my $trans (@solutions) {
    print translate($trans, $crypto), "\n";
  }

} else {

  # new approach
  # try translations one base letter at a time

  @solutions = try2(\%trans);

  for my $trans (@solutions) {
    print translate($trans, $crypto), "\n";
  }

}

exit;


# try translations one base letter at a time
# in ascending order by number of translations

sub try2 {
  my($trans) = @_;

  my @letters = sort { keys %{$trans->{$a}} <=> keys %{$trans->{$b}} }
                     keys %$trans;

  try2_recurse({}, {}, $trans, \@letters, 0);
}


# try all the translations for a base letter,
# recursing through the remaining base letters

sub try2_recurse {
  my($try, $rtry, $trans, $letters, $p) = @_;


  # if this isn't the first base letter,
  # make sure all base words still have at least one real word

  if ($p > 1) {
    foreach my $c (0 .. $#crypto) {
      my $curr = translate($try, $crypto[$c]);
      my $regex = crypto_regex($curr, [ values %$try ]);
      if (!grep /$regex/, @{$words[$c]}) {
        return;
      }
    }
  }


  # no more base letters to translate; found a solution!

  if ($p > $#{$letters}) {
    return $try;
  }


  # recursively try all the translations for the next base letter
  # skip translations which have already been used in this try

  my $l = $letters->[$p];

  my @return;

  foreach my $t (keys %{$trans->{$l}}) {
    next if $rtry->{$t};
    push @return,
      try2_recurse({ %$try, $l => $t }, { %$rtry, $t => $l },
                   $trans, $letters, $p + 1);
  }

  @return;
}


# try all the translations for a base word,
# recursing through the remaining base words

sub try {
  my($trans, $order) = @_;


  # no more base words to translate; found a solution!

  if (not @$order) {
    return $trans;
  }

  my @return;


  # for each real word which is still possible,
  # recursively try all the translations for the next base word

  my $c = $order->[0];
  my $curr = translate($trans, $crypto[$c]);
  my($regex, $template) = crypto_regex($curr, [ values %$trans ]);

  for my $word (@{$words[$c]}) {
    if (my(@matches) = $word =~ /$regex/) {
      unshift @matches, '';

      my %new_trans;
      @new_trans{ keys %$template } = @matches[ values %$template ];

      push @return,
        try( { %$trans, %new_trans },
             [ @{$order}[1..$#$order] ]
           );
    }
  }

  @return;
}


# translate base letters in a word according to the specified translation
# (base letters are in uppercase)

sub translate {
  my($trans, $word) = @_;

  my $from = uc quotemeta join '', keys %$trans;
  my $to   = quotemeta join '', values %$trans;

  eval "\$word =~ tr/$from/$to/";
  $word;
}


# given a base word and a corresponding list of real words,
# return a hash of the possible translations for each base letter
# (no eliminations are performed here)

sub make_trans {
  my($base, $words) = @_;

  my @base = split //, $base;

  my @i = map { $base[$_] =~ /[A-Z]/ ? $_ : () } 0 .. $#base;

  my %trans;

  for my $word (@$words) {
    for my $i (@i) {
      $trans{$base[$i]}{substr $word, $i, 1} = 1;
    }
  }
  return \%trans;
}


# given a base word, a corresponding list of real words, and a hash
# of character classes, remove words which are no longer possible
# uppercase letters in the base word use the character class;
# lowercase letters are matched exactly

sub eliminate_words {
  my($base, $words, $classes) = @_;

  my $re;

  for my $letter (split //, $base) {
    if ($letter =~ /[A-Z]/) {
      $re .= $classes->{$letter};
    } else {
      $re .= $letter;
    }
  }

  $re = qr/$re/;


  # partition the list into possible and impossible words
  # to avoid many small splices

  my($p, $q);

  for ($p = $q = 0; $q < @$words; ++$q) {
    if ($words->[$q] =~ $re) {
      $words->[$p] = $words->[$q]
        unless $p == $q;
      $p++;
    }
  }

  splice(@$words, $p);

  return;
}


# given a base word and a list of letters which have already been used
# create a regex to match possible real words
# when called in a list context, also returns a hash mapping base letters
# to matching groups in the regex
# uppercase letters are wildcards
# lowercase letters are matched literally
# e.g. cXYYZ yields /^c(.)(?!\1)(.)\2(?!\1|\2)(.)$/

sub crypto_regex {
  my($word, $used) = @_;

  my $regex = '^';
  my %template;
  my @avoid;
  my $curr = 0;
  my $dot = '.';

  if ($used and @$used) {
    $dot = '[^' . join('', @$used) . ']';
  }

  foreach (split //, $word) {
    if (/[a-z]/) {
      $regex .= "$_";
    } elsif (/[A-Z]/) {

      if (exists $template{$_}) {
        # repeated occurrence of this base letter
        # match the corresponding backreference

        $regex .= "\\$template{$_}";

      } else {
        # first occurrence of this base letter

        $curr++;

        if (@avoid) {
          # don't match letters matched by other base letters

          $regex .= '(?!' . join('|', @avoid) . ')';
        }

        $regex .= "($dot)";

        $template{$_} = $curr;
        push @avoid, "\\$template{$_}";

      }

    } else {
      warn "ignoring $_";
    }
  }
  $regex .= '$';

  $regex = qr/$regex/;

  return wantarray ? ($regex, \%template) : $regex;
}

__END__

=pod

=head1 NAME

B<cryptosolve> -- solve standard cryptograms

=head1 SYNOPSIS

B<cryptosolve> [B<-w> I<wordlist>] [B<-D>] [B<-E>] [cryptogram]

=head1 DESCRIPTION

B<cryptosolve> finds solutions to standard cryptograms, using an
optimized brute force approach.

The cryptogram may be passed on the command line or via standard
input.  To solve a cryptogram stored in a file, the file should be
directed to standard input, e.g. C<cryptosolve E<lt> cryptogram.txt>.

=head2 OPTIONS

B<cryptosolve> accepts the following options:

=over 4

=item B<-w> I<wordlist>

By default, B<cryptosolve> looks for a file named 'wordlist' in the
same directory as the executable.  Use the B<-w> option to specify the
path to an alternate word list.

=item B<-u>

By default, B<cryptosolve> treats uppercase letters as base letters to
be translated and lowercase letters as final letters.  This allows you
to use it on a partially translated cryptogram.  Use the B<-u> option
when you want to force all letters to uppercase; this saves you from
having to modify the input.

=item B<-D>

Use the B<-D> option to turn on debugging output.

=item B<-E>

Normally, B<cryptosolve> will repeatedly eliminate words until it
reaches a point where no more words can be eliminated.  Use the B<-E>
option to have only one round of elimination performed.  This may be
useful for debugging purposes.

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

Still takes an inordinate amount of time to solve some cryptograms.

=head1 AUTHOR

Ronald J Kimball <rjk-perl@tamias.net>

=head1 COPYRIGHT and LICENSE

This program is copyright 2001, 2002 by Ronald J Kimball.

This program is free and open software.  You may use, modify, or
distribute this program (and any modified variants) in any way you
wish, provided you do not restrict others from doing the same.

=cut

