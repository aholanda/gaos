#!/usr/bin/env perl

use strict;

my $FN='/usr/share/sgb/roget.dat';
# map word identification to string representation of the word
my %id2word;
# map word identification to its degree
my %id2degree;
# map degree to its frequency
my %deg2freq;

open(IN, $FN);

while(<IN>) {
    if ($_ =~ /^\*/) {
	next;
    }

    $_ =~ m /(\d+)(\w+):(.+)\n/;
    $id2word{$1} = $2;
    my @syns = split / /, $3; # synonymous

    $id2degree{$1} = $#syns + 1;
}
close(IN);

for my $id (keys %id2degree) {
    my $deg = $id2degree{$id};

    if (!exists($deg2freq{$deg})) {
	$deg2freq{$deg} = 1;
    } else {
	$deg2freq{$deg}++;
    }
}

my $total_freq = 0;
for my $deg (sort {$b <=> $a} keys %deg2freq) {
    my $freq = $deg2freq{$deg};
    $total_freq += $freq;
}

# cumulative probability
my $cum_prob = 0;
for my $deg (sort {$b <=> $a} keys %deg2freq) {
    $cum_prob += $deg2freq{$deg} / $total_freq;
    print "$deg\t$cum_prob\n";
}
