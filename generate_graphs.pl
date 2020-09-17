#!/usr/bin/env perl

use strict;
use warnings;

####
# This script is used for pre-processing only.
# It can be ignored if the files' integrity of
# graph descriptions in 'data' directed were right.
####

# The linux kernel code files are downloaded in a temporary directory.
my $tmpdir = '/tmp/linux';
system("[ -d $tmpdir ] || mkdir -v $tmpdir");
sub tidy {
    system("[ -d $tmpdir ] && rm -rfv $tmpdir");
}

# The versions to be downloaded are listed in the file 'versions.txt'.
my $fn = "versions.txt";
my @versions = ();
open(my $fh, '<', $fn) or die "cannot open file $fn";
while (<$fh>) {
    chomp;
    push @versions, $_;
}
close($fh);

# Download the source code files of linux kernel.
foreach my $v (@versions) {
    print "$v ";
}

# Cleanup
tidy();