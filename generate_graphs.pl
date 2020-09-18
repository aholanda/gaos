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
use strict;

# PRECONDITIONS
foreach my $bin ("cflow", "lynx") {
    if (system("which $bin > /dev/null") != 0) {
        err("$bin is not installed");
    }
}

# CONSTANTS
use Cwd qw(cwd);
my $PWD = cwd;
my $DATADIR = 'data';
my $TMPDIR = '/tmp/linux';

# HELPERS
sub glog {
    my $level = shift;
    my $task = shift;
    my $operand = shift;
    my $msg = $task . "> " . $operand . "\n";

    for (my $i=0; $i<3; $i++) {
        last if $i == $level;
        $msg = "\t" . $msg;
    }
    print STDERR $msg;
}

# Subroutine tmpdir is used to administer the temporary directory.
sub tmpdir_do {
    my $op = shift;

    if ($op == "rm") {
        # Remove the temporary directory.
        system("[ -d $TMPDIR ] && rm -rf $TMPDIR");
    } elsif ($op == "mkdir") {
        # Create the temporary directory to copy source code.
        system("[ -d $TMPDIR ] || mkdir -v $TMPDIR");
    } else {
        return;
    }
}

# Return an array with the Linux versions listed in the 
# file 'versions.txt', one per line.
# Line comments begin with '#'.
sub versions_get {
    # The versions to be downloaded are listed in the file 'versions.txt'.
    my $fn = $PWD . '/' . "versions.txt";
    
    my @versions = ();
    open(IN, $fn) or die "cannot open file $fn";
    while (<IN>) {
        chomp;
        push @versions, $_;
    }
    close(IN);

    return \@versions;
}

# PROCEDURES
my %index_; # Map name to index
my %name_;  # Map index to name
my $count_ = 0; # Counter to use as next index
sub gindex {
    my $name = shift;

    if (!exists($index_{$name})) {
        $index_{$name} = $count_++;
    }
}

sub gindex_reset {
    %index_ = ();
    $count_ = 0;
}

sub graph_save {
    my $graph_name = shift;
    my $wsep = " "; # Word separator

    $graph_name =~ s/\./_/g;
    my $fn = $PWD . '/' . $DATADIR . '/' . $graph_name . '.dat';
    # Print index
    system("echo '' >". $fn);
    foreach my $name (sort  { $index_{$a} <=> $index_{$b} }keys %index_) {
        my $cmd = "echo " . $index_{$name} . $wsep . $name ." >> " . $fn;
        `$cmd`;
    }
    glog(1, 'saved', $fn)
}

# Do a clean
tmpdir_do('rm');
# Create temporary directory.
tmpdir_do('mkdir');

# Download the source code files of linux kernel.
use File::Fetch;
my $baseurl = 'https://mirrors.edge.kernel.org/pub/linux/kernel';
my $versions = versions_get();
foreach my $ver (@$versions) {
    next if $ver =~ /^#/; # comments start with '#'
    # :TODO: check version string
    my $url = $baseurl . '/' . $ver;
    print "\ncontext> $ver\n";
    # List compressed kernel files ('*.tar.xz') remote files.
    my @rln_xzs = `lynx -dump $url | grep tar.xz | grep https| grep -v bdflush`;
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
        my $where = $ff->fetch(to => $TMPDIR);
        # Uncompress
        my $in = $TMPDIR . '/' . $file;
        my $kernel_name = `basename -z $file .tar.xz`;
        my $out = $TMPDIR . '/' . $kernel_name;
        print "\tuncompress> $in -> $out\n";
        system("tar xfvJ $in -C $TMPDIR > /dev/null");
        # Some files are uncompressed into 'linux' only directory name without the version part.
        # We add the version part to avoid conflict between the versions with the same property.
        system("[ -d $TMPDIR/linux ] && mv -v $TMPDIR/linux $out");

        # Reset index
        gindex_reset();
        # Run cflow to extract the funcion calls
        my @cfiles = `find $out -name *.c`;
        foreach my $cfile (@cfiles) {
            my @funcs = `cflow --depth 2 --omit-arguments $cfile`;
            foreach my $func (@funcs) {
                if ($func =~ /^\s+(.+)\(\)\s*<(.*)>.*/ || 
                    $func =~ /^\s+(.+)\(\)\s*.*/) {
                    my $called = $1;
                    gindex($called);
                } elsif ($func =~ /^(\w+)\(\).*/) {
                    my $callee = $1;
                    gindex($callee);
                } else {
                    print "NOPE> $func";
                }
            }
        }
        # Save the graph description
        graph_save($kernel_name);
        last;
    }
}
