#!/usr/linguist/bin/perl -w

# $Header: $

use strict;
use Getopt::Std;

use vars qw($opt_w $opt_D $opt_E);

getopts('w:DE') || die "Bad options.\n";

my $dict = $opt_w || 'wordlist';

my $DEBUG = $opt_D;
my $ELIMINATE_ONCE = $opt_E;

open(DICT, $dict) or die "Can't open $dict: $!\n";

my @crypto;
if (@ARGV) {
    @crypto = @ARGV;
} else {
    local $/;
    @crypto = split ' ', lc <>;
}

my $crypto = "@crypto";

print "$crypto\n";

@crypto = grep { s/[,.]$//; !/[^a-z]/ } @crypto;

print "@crypto\n";

my @canon = map crypto_canon($_), @crypto;
my @words = map [ length == 1 ? ('a', 'i') : () ], @crypto;

while (<DICT>) {
    chomp;

    next if length == 1;
    next if /[^a-z]/;
    
    my $crypt;

    for my $i (0 .. $#canon) {
        next if length $canon[$i] != length $_;
        next if $canon[$i] ne ($crypt ||= &crypto_canon($_));

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

1;

sub try {
    my($trans, $rtrans, $order) = @_;

    if (not @$order) {
        return $trans;
    }

    my @return;

    my $c = $order->[0];
    my $curr = translate($trans, $crypto[$c]);
    my $canon = crypto_canon($curr);

    for my $word (@{$words[$c]}) {
        my($rc, %new_trans) = crypto_match($curr, $canon, $word, $rtrans);
        if ($rc) {
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

    my $from = quotemeta join '', keys %$trans;
    my $to   = uc quotemeta join '', values %$trans;

    eval "\$word =~ tr/$from/$to/";
    $word;
}

sub make_classes {
    my($base, $words) = @_;

    my @base = split //, $base;

    my %classes;

    for my $word (@$words) {
        for (my $i = 0; $i < length $word; ++$i) {
            $classes{$base[$i]}{substr $word, $i, 1} = 1;
        }
    }
    return \%classes;
}

sub eliminate_words {
    my($base, $words, $classes) = @_;

    my $re;

    for my $letter (split //, $base) {
        $re .= $classes->{$letter};
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

sub crypto_match {
    my($base, $canon, $word, $rtrans) = @_;

    return if length $base != length $word;

    my @base  = split //, $base;
    my @canon = split //, $canon;
    my @word  = split //, $word;

    my %letters;
    my %trans;
    my $next = 'a';

    for my $i (0 .. $#base) {
        if ($canon[$i] eq uc $canon[$i]) {     # uppercase or non-letter
            return if $canon[$i] ne uc $word[$i];
            next;
        }

        if (not exists $letters{$word[$i]}) {
            return if $rtrans->{$word[$i]};

            $letters{$word[$i]} = $next++;
            $trans{$base[$i]} = $word[$i];
        }

        return if $canon[$i] ne $letters{$word[$i]};
    }

    return(1, %trans);
}

sub crypto_canon {
    my($word) = @_;

    my $canon;
    my %letters;
    my $next = 'a';

    foreach (split //, $word) {
        if ($_ !~ /[a-z]/) {
            $canon .= $_;
            next;
        } elsif (not exists $letters{$_}) {
            $letters{$_} = $next++;
        }
        $canon .= $letters{$_};
    }
    $canon;
}

