#!/usr/bin/env perl
use strict;

# This script reproduces the experiment of linux source code
# preferential attachment.

# Map major version to kernel file to download.
# Versions marked with asterisk uncompress to linux/ directory,
# they must be renamed properly according to minor version suffix.
my %vrs2krn = (
    "1.0*" => "linux-1.0.tar.xz",
    "1.1*" => "linux-1.1.95.tar.xz",
    "1.2*" => "linux-1.2.13.tar.xz",
    "1.3*" => "linux-1.3.100.tar.xz",
    "2.1*" => "linux-2.1.132.tar.xz",
    "2.2"  => "linux-2.2.26.tar.xz",
    "2.3*" => "linux-2.3.99-pre9.tar.xz",
    "2.4"  => "linux-2.4.37.11.tar.xz",
    "2.5"  => "linux-2.5.75.tar.xz",
    "2.6"  => "linux-2.6.39.tar.xz",
    "3.x"  => "linux-3.19.8.tar.xz",
    "4.x"  => "linux-4.14.14.tar.xz"
    );

# return the link of kernel.org to download compressed files
sub get_lnk {
    my $vrs = shift;
    my $fn = shift;

    my $baselnk = "https://www.kernel.org/pub/linux/kernel/";
    
    return $baselnk."v".$vrs."/".$fn;
}

# print command to be executed to standard error and execute it
sub ecmd {
    my $cmd = shift;    
    print STDERR $cmd."\n";
    `$cmd`;
}

################################################################
# 1st STEP: download and extract kernel files
sub download_and_extract_files {
    my $cmd;
    
    for my $vrs (sort keys %vrs2krn) {
	my $fn = $vrs2krn{$vrs};
	my $dir = `basename $fn .tar.xz`;	

	chomp($dir);
	
	if (-d $dir) {
	    print "$dir exists!\n";
	} else 	{
	    my $lnk = &get_lnk($vrs, $fn);
	    &ecmd("wget $lnk");
	    &ecmd("tar xfvJ $fn 2>/dev/null");
	    if (-d "linux") {
		&ecmd("mv linux $dir"); 
	    }	    
	    &ecmd("rm -f $fn");
	}
    } 
}

&download_and_extract_files();
