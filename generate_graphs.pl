#!/usr/bin/env perl

=head1 NAME

generate_graphs - generate function calls graphs from linux kernel

=head1 DESCRIPTION

C<generate_graphs> download linux kernel source files from kernel.org, 
generate call graphs using C<cflows> and write them into a file in a 
format suitable for graph description.

This script may be used for pre-processing only. It can be ignored if 
the files' integrity of graph descriptions in 'data' directed were right.

:TODO: generate checksum from data

=cut

# Preconditions
foreach my $bin ("cflow", "lynx") {
    if (system("which $bin > /dev/null") != 0) {
        print STDERR "fatal: $bin is not installed";
        exit 1;
    }
}

# The linux kernel code files are downloaded in a temporary directory.
my $tmpdir = '/tmp/linux';
sub tidy {
    system("[ -d $tmpdir ] && rm -rf $tmpdir");
}
# Do a clean
tidy();
# Create the source kernel directory again.
system("[ -d $tmpdir ] || mkdir -v $tmpdir");

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
use File::Fetch;
my $baseurl = 'https://mirrors.edge.kernel.org/pub/linux/kernel';
foreach my $ver (@versions) {
    next if $ver =~ /^#/; # comments start with '#'
    # :TODO: check version string
    $url = $baseurl . '/' . $ver;
    print "\ncontext> $ver\n";
    # List compressed kernel files ('*.tar.xz') remote files.
    @rln_xzs = `lynx -dump $url | grep tar.xz | grep https| grep -v bdflush`;
    # Download files and uncompress them.
    for my $rln_xz (@rln_xzs) {
        my $lnk = undef;
        my $file = undef;
        if ($rln_xz =~ /.*\d+\..*(https.+tar\.xz)\n*/) {
            $lnk = $1;
            $file = substr $lnk, rindex($lnk, '/') + 1;
        }
        # Download
        print "\tget> $lnk\n";        
        my $ff = File::Fetch->new(uri => $lnk);
        my $where = $ff->fetch(to => $tmpdir);
        # Uncompress
        my $in = $tmpdir . '/' . $file;
        my $out = $tmpdir . '/' . `basename -z $file .tar.xz`;
        print "\tuncompress> $in -> $out\n";
        system("tar xfvJ $in -C $tmpdir > /dev/null");
        # Some files are uncompressed into 'linux' only directory name without the version part.
        # We add the version part to avoid conflict between the versions with the same property.
        system("[ -d $tmpdir/linux ] && mv -v $tmpdir/linux $out");

        # Run cflow to extract the funcion calls
        my @cs = `find $out -name *.c`;
        foreach my $c (@cs) {
            my @funcs = `cflow --depth 2 --omit-arguments $c`;
            foreach my $func (@funcs) {
                if ($func =~ /^\s+(.+)\(\)\s*.*/) {
                    my $called = $1;
                    print "\t->$called\n";
                } elsif ($func =~ /^(\w+)\(\).*/) {
                    my $callee = $1;
                    print "$callee->\n";
                } else {
                    print "func";
                }
            }
        }
        last;
    }
}
