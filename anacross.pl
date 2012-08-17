#!/usr/local/bin/perl -w

use strict;

# solve anacrossagrams, as found at http://rinkworks.com/brainfood/

my $size = shift @ARGV;

if (@ARGV != $size * 2) {
    die "$0: wrong number of arguments.\n";
}

my @across = splice @ARGV, 0, $size;
my @down   = splice @ARGV, 0, $size;

my $word;
my @a_ltrs;
foreach $word (@across) {
    if (length $word != $size) {
        die "'$word' is not of length $size.\n";
    }

    my %tmp;
    foreach (split //, $word) {    
        $tmp{$_}++;
    }
    push @a_ltrs, \%tmp;
}

my @d_ltrs;
foreach $word (@down) {
    if (length $word != $size) {
        die "'$word' is not of length $size.\n";
    }

    my %tmp;
    foreach (split //, $word) {
        $tmp{$_}++;
    }
    push @d_ltrs, \%tmp;
}

my $count = 0;
my $oldcount = -1;
my $board;

my ($a, $d);
for $a (0 .. @a_ltrs - 1) {
    for $d (0 .. @d_ltrs - 1) {
        $board->[$a][$d] = '.';
    }
}

my @share;

while ($count != $oldcount && $count < $size * $size) {
    $oldcount = $count;
    for ($a = 0; $a < @a_ltrs; ++$a) {
        for ($d = 0; $d < @d_ltrs; ++$d) {
            next if $board->[$a][$d] ne '.';

            @share = intersect($a_ltrs[$a], $d_ltrs[$d]);
            if (@share == 1) {
                $board->[$a][$d] = $share[0];
                $count++;
                $a_ltrs[$a]{$share[0]}--;
                $d_ltrs[$d]{$share[0]}--;
            }
        }
    }
}

print "\n";
foreach (@$board) {
    print join '', @$_, "\n";
}
print "\n";

sub intersect {
    my @ret;
    foreach (keys %{$_[1]}) {
        next unless $ {$_[1]}{$_};
        push @ret, $_ if $ {$_[0]}{$_};
    }
    return @ret;
}
