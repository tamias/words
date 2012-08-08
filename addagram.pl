#!/usr/local/bin/perl

# find add-a-grams; sequences of words formed by starting with a
# 3-letter word, adding a letter and rearranging to form a 4-letter
# word, and so on

use strict;
use warnings;

$| = 1;

use Getopt::Long;

GetOptions(
  "wordlist=s" => \ (my $wordlist = 'wordlist'),
) or die "usage: addagram [--wordlist=<wordlist>]";

open(my $dict_fh, '<', $wordlist) or     # open word list
  die "Unable to open $wordlist: $!\n";

my(%words, @letters);

while (<$dict_fh>) {
  chomp;
  my $letters = join '', sort split //;
  if (not exists $words{$letters}) {
    $words{$letters} = [$_, 1];
    push @{ $letters[length] }, $letters;
  } else {
    # just for fun, keep track of the word count for each set of letters
    $words{$letters}[1]++;
  }
}

my(@solutions, @stack, $found);

my $i = $#letters;
SEARCH:
while ($i > 3 and !$found) {
  print "Trying length $i.\n";

  # try each word at this length
  for my $letters (@{ $letters[$i] }) {
    @stack = [ $letters ];
    while (@stack) {

      # advance the next attempt
      my $test = pop @stack;

      if (length $test->[-1] == 3) {
        # found a solution!
        # note it, print it, go back to look for more
        $found = 1;
        print_solution($test);
        last SEARCH;
        next;
      }

      # look for branches from the last set of letters
      my $continue;
      for my $branch (branch($test->[-1])) {

        if (exists $words{$branch}) {
          # found a branch!
          # note it and push it on the stack
          $continue = 1;
          push @stack, [ @$test, $branch ];
        }
      }

      if (!$continue) {
        # no branches found; prune the dead end
        delete $words{ $test->[-1] };
      }

    }
  }

  # all done with this length; go one shorter
  $i--;
}

# given a set of letters, return all possible branches
#   (set minus one letter)
sub branch {
  my($letters) = @_;

  # get all possible branches
  my @branches = map { my $x = $letters; substr($x, $_, 1) = ''; $x }
                     0 .. length($letters) - 1;

  # remove duplicate branches
  my %uniq;
  @uniq{@branches} = ();

  return sort keys %uniq;
}

sub print_solution {
  my($solution) = @_;
  for my $letters (@$solution) {
    print "$words{$letters}[0] ($words{$letters}[1]) ";
  }
  print "\n";
}

__END__
