#!/usr/bin/env perl

use strict;
use Gaos;

my $TRUE = 1;
my $FALSE = 0;

my $gaos = Gaos->new();
$gaos->verbose($TRUE);

if ($#ARGV < 0 || $#ARGV > 1) {
    &usage($ARGV[-1]);
} elsif ($#ARGV == 0 && $ARGV[0] eq "--reset-database") {
    my $in;
    print "Are you sure you want to destroy and create all tables of database again? (y/[n])? ";
    $in = <STDIN>;
    chomp $in;
    if ($in eq "y" || $in eq "Y") {
	$gaos->db_create_tables();
    }
} else {
    my $has_static_functions = 1; # default: dont ignore

    if ($#ARGV == 0) {
	$gaos->db_load_function_calls($ARGV[0], $has_static_functions);
    } elsif ($#ARGV == 1 && $ARGV[0] eq "--no-static") {
	$has_static_functions = 0;
	$gaos->db_load_function_calls($ARGV[1], $has_static_functions);
    } else {
	&usage($ARGV[-1]);
    }     
}

sub usage {
    my $prg = shift;
    my $dbname = $gaos->db_name();
    
    print STDERR qq(Usage: $prg [OPTIONS]
where OPTIONS:
\t[--no-static] <directory>
\t\tLoad into database the graph of function calls from the <directory>.
\t\tIMPORTANT: DONT use backslash in the <directory>.
\t--no-static (optional) - ignore static functions, default is to consider them.

\t--reset-database
\t\tRemove the database file '$dbname'. Be careful, all loaded data will be 
\t\tdeleted. Choose this option if you want to start again with fresh ideas.
);
    
}
