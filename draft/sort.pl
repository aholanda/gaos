#!/usr/bin/perl

use strict;

my $fn = $ARGV[0];
my %func2centr;
my $lim = 100; # limit in pagination
my $i = 1;

if ($ARGV[1]) {
    $lim = $ARGV[1];
}

open(IN, $fn) or die "Could not open '$fn'\n";
while (<IN>) {
    chomp;
    my ($func, $val) = split /;/;
    $func2centr{$func} = $val;
}
close(IN);

foreach my $func (sort { $func2centr{$b} <=> $func2centr{$a} } keys %func2centr) {
    printf "%d. %-8s\t%s\n", $i, $func, $func2centr{$func};
    $i++;

    if ($i > $lim) {
	last;
    } 
}
