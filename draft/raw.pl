#!/usr/bin/env perl

use Chart::Gnuplot;
use strict;
use warnings;

# CONST
my $FALSE = 0;
my $TRUE = 1;
my $EDGE_LINK = '@'; # u@v
my $FIELD_SEPARATOR = "\t";

# GLOBALS
my $MIN_FUNCTIONS = 60; # Minimum number of functions in the subsystem to consider in the study
my %Proto; # Table that maps prototype function names to ones (fake value)
my %Coords; # Hash of Hash that maps subsystem and function name to its id (coordinate in the ideogram)
my %Edges; # Table that maps edge label (u->v) to its weight (integer)
my $NE=0; # Total number of edges, with repetitions
my %Subsys; # Table that maps the number of functions in the subsystem (subdirectory)
my %Functions; # Table that map functions to sybsystems, this is needed beacuse called function has no info about subsystem
my $NOCTX=0; # Number of files without context in subsystems
my %ID2VV; # Map identification to complete namespace of functions, eg., 8888=drivers.flashcard_read

sub usage {
    die <<"USAGE";
Usage: $0 [--extract-functions <linux-dir>] | [--write-circos-conf <linux-dir>]
 | [--degree-distrib <dot-file> | 
 [--plot-degree-distrib-from-data-files <file1.dat> <file2.dat> ... <filen.dat>]

Where:
--extract-functions <linux-dir>: extract function calls edges u->v and write <linux-dir>.dot file.

--plot-degree <dot-file>: plot cumulative degree distribution from <dot-file>.

--plot-degree-distrib-from-data-files: plot cumulative degree distribution from a 
set of data files <file1.dat> <file2.dat> ... <filen.dat>. In the first column of each 
file must be degree, and in the second cumulative probability. The name of output file 
is taken from the input file names pattern.
USAGE
}

if ($#ARGV < 1) {
    &usage();    
}

my $flag = $ARGV[0];
my $file_or_dir = $ARGV[1]; # Linux directory or dot file
my $verbose = $TRUE; # verbose is set inside code for debug purposes
$file_or_dir =~ s/\///g; # cut / if exits

#    extract_function_names($dir, $verbose);

if ($flag eq "--extract-functions") {
    extract_function_calls_from_source_code($file_or_dir, $verbose);
} elsif ($flag eq "--plot-degree") {
    &plot_degree_distrib($file_or_dir, $verbose)
} elsif ($flag eq "--plot-degree-distrib-from-data-files") {
    &plot_degree_distrib_from_data_files(\@ARGV, $verbose);    
} else {
    &usage();
}

#    &run_circos($dir);
#print "There are $NOCTX files in $dir without subsystem context that probably are macros!\n";

# PROTOTYPES
# Extract the function names from header files
# usign ctags program
sub extract_function_names {
    my $dir = shift;
    my $verbose = shift;
    
    my @headers = `find $dir/include -name *.h`;

    foreach my $fn (@headers) {
	chomp $fn;
	my @out = `ctags -x --c-kinds=fp $fn`;
	foreach my $line (@out) {
	    my @tokens = split / /, $line;
	    if ($tokens[1] eq "prototype") {
		my $funcname = $tokens[0];
		
		$Proto{$funcname} = 1;

		if ($verbose) {
		    print "H: ".$funcname."\n";
		}
	    }
	}
    }
}

# FUNCTIONS
# Extract the function names from source code
# using cflow program
sub extract_function_calls_from_source_code {
    my $dir = shift;
    my $verbose = shift;

    # List subdirectories inside Linux directory
    my @subdirs = `find $dir/ -maxdepth 1 -type d`;

    foreach my $subdir (@subdirs) {
	chomp $subdir; # this is Essential
	my @tks = split /\//, $subdir;
	if ($#tks >= 1) { # MUST have a directory name after linux-xx-xx/
	    &__extract_function_calls_from_source_code($subdir, $verbose);
	    #last;
	}	
    }
    &write_dot_file($dir);
    &plot_degree_distrib($dir.".dot", $verbose);

    return $dir;
}

sub add_edge {
    my @vs = @_;

    $NE++;
    
    my $e = $vs[0].$EDGE_LINK.$vs[1];
    if (exists($Edges{$e})) {
	$Edges{$e}++;
    } else {
	$Edges{$e} = 1;
    }
    print STDERR $e."\n" if $verbose;
}


sub __extract_function_calls_from_source_code {
    my $dir = shift;
    my $verbose = shift;

    my ($version, $subsys) = split /\//, $dir;
    $Subsys{$subsys} = 0;
    
    my ($u, $v);

    my $cmd = "find $dir -name *.c";
    print "$cmd\n";
    my @sources = `$cmd`;
    
    # to extract the function names and the subsystem
    # two passes are needed, in the first an index of
    # subsystem and caller function mapped with an global
    # ID is generated. This ID is used as coordenate
    # to the function.
    # In the second pass, the links are created and put
    # in the ideogram.
    foreach my $fn (@sources) {
	$cmd = "\tcflow -b -d 2 $fn";
	print "$cmd" if $verbose;
	my @out = `$cmd`;
	
	foreach my $line (@out) {
	    if ($line =~ m/^\w+.*/) {
		chomp $line;
		$line =~ m/(\w+)\(\).*/;
		my $funcname = $1;

		$NV++;
		$Coords{$subsys}{$funcname} = $NV;
		$ID2VV{$NV} = $subsys.$PATH_SEPARATOR.$funcname;
		$Subsys{$subsys}++;
		$Functions{$funcname} = $subsys;
	    }
	} # END foreach my $line
    } # END foreach my $fn
	  
    foreach my $fn (@sources) {
	$cmd = "\tcflow -b -d 2 $fn";
	print "$cmd" if $verbose;
	my @out = `$cmd`;
      LINE:
	foreach my $line (@out) {
	    # CALLER
	    if ($line =~ m/^\w+.*/) {
		chomp $line;
		$line =~ m/(\w+)\(\).*/;
		$u = $1;

		# $u has always a subsystem because it is the source
		$u = $subsys.$PATH_SEPARATOR.$u;

		next LINE;
		
	    } else  {
		chomp $line;
		$line =~ m/\s+(\w+)\(\).*/;
		$v = $1;
		
		if (!exists($Functions{$v})) {
		    $NOCTX++;
		    next LINE;
		    # keep here as alternative to be strict
		    #die "$v does not exists in subsystem table!\n";
		} else {
		    $v = $Functions{$v}.$PATH_SEPARATOR.$v;
		}
	    }
	    &add_edge($u, $v);
	}
    } # END_foreach my $fn...
}

sub write_dot_file {
    my $dir = shift;
    my %ids; # vertex id is its coordinate that is unique
    
    my $fn = $dir.".dot";

    open(DOT, ">$fn");

    print DOT "digraph D {\n";
    # retrieve vertex indices
    foreach my $key (keys %Edges) {
	my ($uu, $vv) = split /$EDGE_LINK/, $key;

	my ($u_subsys, $u) = split /\./, $uu;
	my ($v_subsys, $v) = split /\./, $vv;
	
	my $u_coord = $Coords{$u_subsys}{$u};
	if (!exists($ids{$uu})) {
	    $ids{$uu} = $u_coord;
	}

	my $v_coord = $Coords{$v_subsys}{$v};
	if (!exists($ids{$vv})) {
	    $ids{$vv} = $v_coord;
	}	
    }
    # print vertices
    foreach my $id (keys %ID2VV) {
	print DOT "\t".$id."\t["."label=\"".$ID2VV{$id}."\"];\n";
    }
    # print edges
    foreach my $key (keys %Edges) {
	my ($uu, $vv) = split /$EDGE_LINK/, $key;
	
	if ($uu eq "" || !$ids{$uu} || $vv eq "" || !$ids{$vv}) {
	    next;
	}

	print DOT "\t".$ids{$uu}." -> ".$ids{$vv}.";\n";
    } 
    print DOT "}\n";
    close(DOT);
    print STDERR "Wrote $fn\n"
}

sub plot_degree_distrib {
    my $fn = shift;
    my $verbose = shift;
    my @x = ();
    my @y = ();

    my %Degree; # hash of hash
    my $cmd;
    
    open(IN, "$fn") or die "Could not open $fn";
    while(<IN>) {
	chomp;
	if ($_ =~ /->/) {
	    $_ =~ m/^\s+(\d+)\s+->\s+(\d+)\s*./;
	    my $u = $1;
	    my $v = $2;

	    print STDERR "\t".$u." -> ". $v . "\n" if $verbose;

	    if (!exists($Degree{"out"}{$u})) {
		$Degree{"out"}{$u} = 1;
	    } else {
		$Degree{"out"}{$u}++;
	    }

	    if (!exists($Degree{"in"}{$v})) {
		$Degree{"in"}{$v} = 1;
	    } else {
		$Degree{"in"}{$v}++;
	    }
	}
    }
    close(IN);


    my %Rank = ("in" => 0, "out" => 0); # hash of hash of degree type, degree value and its frequence
    my @deg_ts = ("in", "out");
    foreach my $deg_t  (@deg_ts) {
	
	# degree are appended to temporary log files
	$fn =~ s/dot/log/g;
	open(LOG, ">>/tmp/$fn");
	
	my $sum = 0;
	foreach my $v (keys %{ $Degree{$deg_t} }) {
	    my $deg = $Degree{$deg_t}{$v};

	    my $vv = $ID2VV{$v};
	    print LOG $deg_t."degree($vv)=$deg\n";

	    if (!exists($Rank{$deg}{$deg_t})) {
		$Rank{$deg}{$deg_t} = 1;
	    } else {
		$Rank{$deg}{$deg_t}++;
	    }
	    $sum++;
	}
	close(LOG);
	print STDERR "Total ".$deg_t."degree frequency: $sum\n";
	print STDERR "Append ".$deg_t."degree values log file /tmp/$fn\n";
    } # END_foreach_my_$deg_t
	
    # WRITE DATA
    $fn =~ s/log/dat/g;
    my $data_fn = $fn;
    open(DAT, ">$data_fn");
    my $cum_prob = 0;
    my $freq;
    foreach my $deg (sort {$b<=>$a}  keys %{ $Rank{$deg} }) {
	print STDERR $deg.$FIELD_SEPARATOR.$Rank{"in"}{$deg}."\t".$Rank{"out"}{$deg}."\n" if $verbose;
	print DAT $deg.$FIELD_SEPARATOR.$Rank{"in"}{$deg}."\t".$Rank{"out"}{$deg}."\n";
    }
    close(DAT);
    print STDERR "Wrote $data_fn\n";
	
    # Write using GNUPLOT
    $fn =~ s/dat/gnuplot/g;
    my $in_fn = $fn;
    $fn =~ s/gnuplot/pdf/g;
    my $out_fn = $fn;
    $fn =~ s/\.pdf//g;
    
    my $gnuplot_cmds = << "GNUPLOT_CMDS";
    set terminal pdf enhanced color solid
	set output "$out_fn"
	#set title "Indegree distribution"
	set logscale xy
	set xlabel 'Indegree'
	set ylabel 'Pr(x>=Indegree)'
	f(x) = x**a
	fit f(x) '$data_fn' via a
	plot f(x) title 'x^{-a}', \"$data_fn\" title '$fn'
	print a
GNUPLOT_CMDS
	
	open(GNUPLOT, ">$in_fn");
	print GNUPLOT $gnuplot_cmds;
	close(GNUPLOT);
	print STDERR "Wrote $in_fn\n";
	$cmd = "gnuplot $in_fn\n";
	print STDERR $cmd;
	#`$cmd`;
	#system("evince $out_fn&");
	

    }

sub plot_degree_distrib_from_data_files {
    my $dat_fns = shift;
    my $verbose = shift;

    my $out_fn = 'gaos.pdf';
    
    my @xs; # arrays of arrays with x coordinates
    my @ys; # arrays of arrays with y coordinates
    my @pts;
    
    my $chart = Chart::Gnuplot->new(
	output => $out_fn,
	logscale=>'xy',
	);

    my @fns = @$dat_fns;
    for (my $i=1; $i<=$#fns; $i++) {
	open(DAT, $fns[$i]);
	while (<DAT>) {
	    chomp;
	    my ($deg, $cum_prob) = split /$FIELD_SEPARATOR/;	    
	    push @{$xs[$i]}, $deg;
	    push @{$ys[$i]}, $cum_prob;
	    print $deg."\t".$cum_prob."\n" if $verbose;
	}
	close(DAT);
    }

    for (my $i=1; $i<=$#fns; $i++) {
	$fns[$i] =~ m/(.+)\.dat/;
	my $title = $1;
	
	my $pts = Chart::Gnuplot::DataSet->new(
	    xdata => \@{$xs[$i]},
	    ydata => \@{$ys[$i]},
	    style => 'linespoints',
	    title => $title,
	    );

	push @pts, $pts;
    }
    $chart->plot2d(@pts);
    
    print "Wrote $out_fn\n";
}

