#!/usr/linguist/bin/perl -w

# $Header: /usr/people/rjk/words/RCS/cryptosolve.pl,v 1.2 2001/08/20 21:08:31 rjk Exp rjk $

use strict;
use Getopt::Std;

use vars qw($opt_w $opt_u $opt_D $opt_E);

getopts('w:uDE') || die "Bad options.\n";

my $dict = $opt_w || 'wordlist';

my $force_upper = $opt_u;

my $DEBUG = $opt_D;
my $ELIMINATE_ONCE = $opt_E;

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

my $crypto = "@crypto";

print "$crypto\n";

@crypto = grep { s/[,.]$//; /^[a-zA-Z]+$/ } @crypto;

print "@crypto\n";

my @regex = map scalar(crypto_regex($_)), @crypto;
my @words = map [ length == 1 ? ('a', 'i') : () ], @crypto;

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


my $no_words;
my $total = 0;

for (@words) {
    if (!@$_) {
        $no_words = 1;
    }
    $total += @$_;
    print scalar(@$_), ' ' if $DEBUG;
}
print "\n" if $DEBUG;

if ($no_words) {
    die "No translations were found in the word list.\n";
}

my $last_total = 0;

while ($total != $last_total) {

    my %classes = %{ make_classes($crypto[0], $words[0]) };

    for my $i (1 .. $#crypto) {
        my $tmp = make_classes($crypto[$i], $words[$i]);

        foreach my $base (keys %$tmp) {
            if (not $classes{$base}) {
                $classes{$base} = $tmp->{$base};
                next;
            }
            foreach my $sol (keys %{$classes{$base}}) {
                delete $classes{$base}{$sol}
                  unless $tmp->{$base}{$sol};
            }
        }
    }

    my %definite = ();

    foreach my $base (sort { keys %{$classes{$a}} <=> keys %{$classes{$b}} }
                           keys %classes) {
        my @keys = keys %{$classes{$base}};
        if (@keys == 1 and not exists $definite{$keys[0]}) {
            $definite{$keys[0]} = 1;
        } elsif (keys %definite) {
            my @del = delete @{$classes{$base}}{keys %definite};
            redo if grep $_, @del;
        }
    }

    my @no_trans;

    foreach my $base (sort keys %classes) {
        if (not %{$classes{$base}}) {
            push @no_trans, $base;
        }

        $classes{$base} = '[' . join('', sort keys %{$classes{$base}}) . ']';
        print "$base $classes{$base}\n" if $DEBUG;
    }

    if (@no_trans) {
        die "No possible translations for @no_trans.\n";
    }

    for my $i (0 .. $#crypto) {
        eliminate_words($crypto[$i], $words[$i], \%classes);
    }

    $last_total = $total;
    $total = 0;

    for (@words) {
        $total += @$_;
        print scalar(@$_), ' ' if $DEBUG;
    }
    print "\n" if $DEBUG;

    last if $ELIMINATE_ONCE;

}

my @order = sort { @{$words[$a]} <=> @{$words[$b]} ||
                   length $crypto[$b] <=> length $crypto[$a]
                 } 0 .. $#words;


my @solutions = try({}, {}, \@order);

for my $trans (@solutions) {
    print translate($trans, $crypto), "\n";
}

exit;

sub try {
    my($trans, $rtrans, $order) = @_;

    if (not @$order) {
        return $trans;
    }

    my @return;

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
                   { reverse(%$trans, %new_trans) },
                   [ @{$order}[1..$#$order] ]
                 );
        }
    }

    @return;
}

sub translate {
    my($trans, $word) = @_;

    my $from = uc quotemeta join '', keys %$trans;
    my $to   = quotemeta join '', values %$trans;

    eval "\$word =~ tr/$from/$to/";
    $word;
}

sub make_classes {
    my($base, $words) = @_;

    my @base = split //, $base;

    my @i = map { $base[$_] =~ /[A-Z]/ ? $_ : () } 0 .. $#base;

    my %classes;

    for my $word (@$words) {
        for my $i (@i) {
            $classes{$base[$i]}{substr $word, $i, 1} = 1;
        }
    }
    return \%classes;
}

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
                $regex .= "\\$template{$_}";
            } else {
                $curr++;
                if (@avoid) {
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

B<cryptosolve> [B<-w> I<wordlist>] [B<-D>] [B<-E>]

=head1 DESCRIPTION

B<cryptosolve> finds solutions to standard cryptograms.

=head2 OPTIONS

B<cryptosolve> accepts the following options:

=over 4

=item B<-w> I<wordlist>

By default, B<cryptosolve> looks for a file named 'wordlist' in the
same directory as the executable.  Use the B<-w> option to specify the
path to an alternate word list.

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
http://personal.riverusers.com/~thegrendel/software.html.

=back

=head1 BUGS

Still takes an inordinate amount of time to solve some cryptograms.

=head1 AUTHOR

B<cryptosolve> was written by Ronald J Kimball,
I<rjk@linguist.dartmouth.edu>.

=head1 COPYRIGHT and LICENSE

This program is copyright 2001 by Ronald J Kimball.

This program is free and open software.  You may use, modify, or
distribute this program (and any modified variants) in any way you
wish, provided you do not restrict others from doing the same.

=cut

