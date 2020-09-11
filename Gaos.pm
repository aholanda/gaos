package Gaos;

use DBI;
use strict;
use vars qw($VERSION);
$VERSION = '0.01';

my $DBNAME = 'linux.db';

my $NV=0; # Total number of vertices
my $NE=0; # Total number of edges
my $PATH_SEPARATOR = "."; # separate path subsys.function_name
my %Functions; # Table that map functions to sybsystems, this is needed beacuse called function has no info about subsystem
my $NOCTX=0; # Number of files without context in subsystems
# map degree type to prefix of degree type
my %pref2degt = ("in" => "to", "out" => "from");

sub new {
    my $package = shift;
    return bless({}, $package);
}

sub verbose {
    my $self = shift;
    if (@_) {
	$self->{'verbose'} = shift;
    }
    return $self->{'verbose'};
}

sub db_name {
    my $self = shift;

    return $DBNAME;
}

sub db_connect {
    my $driver = "SQLite";
    my $database = $DBNAME;
    my $dsn = "DBI:$driver:$database";
    my $userid = "";
    my $password = "";
    my $dbh = DBI->connect($dsn, $userid, $password, { RaiseError => 1 })
	or die $DBI::errstr;

    return $dbh;
}

################################################################
# DATABASE
################################################################

sub db_create_tables {
    my $self = shift;
    
    print STDERR "removing database $DBNAME\n";
    `rm -f $DBNAME`; # remove database

    my $dbh = &db_connect;

    print STDERR "creating tables...\n" if $self->{'verbose'};

    open(SQL, 'graph.sql');
    while(<SQL>) {
	print STDERR $_;
	my $rv = $dbh->do($_);
	if($rv < 0) {
	    print $DBI::errstr;
	}
    }
    $dbh->disconnect();
    close(SQL);
}
    
sub db_add_graph {
    my ($self, $dbh, $name, $has_static_function) = @_;
    my @row;
    
    my $sth = $dbh->prepare("INSERT INTO graph (name, has_static_function) VALUES (?,?)");    
    $sth->execute($name, $has_static_function) or die $DBI::errstr;
    $sth->finish;

    $sth = $dbh->prepare("SELECT id FROM graph WHERE name=?");
    $sth->execute($name) or die $DBI::errstr;
    @row = $sth->fetchrow_array();

    if (!$row[0] || $sth->rows <= 0) {
	die "ERROR: problems during insertion of graph information.\n";
    }    
    return $row[0];
}

sub db_add_vertex {
    my ($self, $dbh, $graph_id, $func_name, $func_id) = @_;

    print STDERR "\tG($graph_id, $func_id) <- V($func_name)\n";
    
    my $sth = $dbh->prepare("INSERT INTO vertex (id, graph_id, name) VALUES (?,?,?)");
    $sth->execute($func_id, $graph_id, $func_name);
    $sth->finish;
}

sub db_get_vertex_id {
    my ($dbh, $graph_id, $func_name) = @_;
    my @row;
    
    my $sth = $dbh->prepare("SELECT id from vertex WHERE graph_id=? AND name=?");
    $sth->execute($graph_id, $func_name) or die $DBI::errstr;
    @row = $sth->fetchrow_array();
    
    if(!$row[0] || $sth->rows <= 0) {
	die "ERROR: Function $func_name was not found in database.\n";
    }
    return $row[0];
}

sub db_add_arc {
    my ($self, $dbh, $gid, $u, $v) = @_;
    my @vs = ($u, $v);
    my @row;
    my $sth;
    
    my $from_id = db_get_vertex_id($dbh, $gid, $u);
    my $to_id = db_get_vertex_id($dbh, $gid, $v);

    $sth = $dbh->prepare("SELECT weight from arc WHERE graph_id=? AND from_id=? AND to_id=?");
    $sth->execute($gid, $from_id, $to_id) or die $DBI::errstr;
    @row = $sth->fetchrow_array();
    
    # arc does not exist, insert it
    if(!@row) {
	$NE++;
	my $a = "A($u ($from_id), $v ($to_id), 1)";
	print STDERR "\tG($gid,$NE) <- $a\n" if $self->{'verbose'};

	my $stmt = qq(INSERT INTO arc (graph_id, from_id, to_id, weight)
		      VALUES ($gid, $from_id, $to_id, 1));
	$dbh->do($stmt) or  die $DBI::errstr;
	
	return;
    }
    
    # ARC exists
    my $w = $row[0] + 1.0; # increase weight by one

    print STDERR "\tG($gid) <-* A($u, $v, $w)\n" if $self->{'verbose'};
    
    $sth = $dbh->prepare("UPDATE arc SET weight=? WHERE graph_id=? AND from_id=? AND to_id=?");
    $sth->execute($w, $gid, $from_id, $to_id) or die $DBI::errstr;    
    $sth->finish;
}

sub db_load_function_calls {
    my ($self, $dir, $has_static_functions) = @_;
    my $dbh;
    my $sth;
    my $graph_id;
    my @subdirs;
    
    $dbh = &db_connect();

    $graph_id = &db_add_graph($self, $dbh, $dir, $has_static_functions);

    # List subdirectories inside Linux directory
    @subdirs = `find $dir/ -maxdepth 1 -type d`;

    # The basic algorithm work in two passes    
    # First, load function definitions (all vertices) into database
    foreach my $subdir (@subdirs) {
	chomp $subdir; # this is Essential
	my @tks = split /\//, $subdir;
	if ($#tks >= 1) { # MUST have a directory name after linux-xx-xx/
	    &db_load_function_defs($self, $subdir, $dbh, $graph_id, $has_static_functions);
	    #last;
	}	
    }
    # Secondly, load function calls u->v (all arcs) into database
    foreach my $subdir (@subdirs) {
	chomp $subdir; # this is Essential
	my @tks = split /\//, $subdir;
	if ($#tks >= 1) { # MUST have a directory name after linux-xx-xx/
	    &__db_load_function_calls($self, $subdir, $dbh, $graph_id, $has_static_functions);
	    #last;
	}	
    }    

    # stored number of ignored functions
    $sth = $dbh->prepare("UPDATE graph SET ignored_functions=? WHERE id=?");
    $sth->execute($NOCTX, $graph_id) or die $DBI::errstr;    
    $sth->finish;
    print STDERR $NOCTX." functions were ignored\n";

    $dbh->disconnect;
    
    return $dir;
}

sub __get_source_files_list {
    my $dir = shift;
    my $cmd;
    my @sources;
    
    $cmd = "find $dir -name *.c";
    print "$cmd\n";
    @sources = `$cmd`;

    return @sources;
}

sub db_load_function_defs {
    my ($self, $dir, $dbh, $graph_id, $has_static_functions) = @_; 
    my ($u, $v);
    my $cflow_flags = "";
    my $cmd;
    my @sources;
    
    my ($version, $subsys) = split /\//, $dir;

    if ($has_static_functions == 0) {
	$cflow_flags .= " -i -s ";
    }
    
    @sources = &__get_source_files_list($dir);

    # to extract the function names and the subsystem
    # two passes are needed, in the first an index of
    # subsystem and caller function mapped with an global
    # ID is generated. This ID is used as coordenate
    # to the function.
    # In the second pass, the arcs are created 
    foreach my $fn (@sources) {
	$cmd = "\tcflow -b -d 2 ".$cflow_flags." $fn";
	#print "$cmd" if $self->verbose;
	my @out = `$cmd`;
	
	foreach my $line (@out) {
	    if ($line =~ m/^\w+.*/) {
		chomp $line;
		$line =~ m/(\w+)\(\).*/;
		my $funcname = $1;

		$NV++;
		$Functions{$funcname} = $subsys;

		my $fname = $subsys.$PATH_SEPARATOR.$funcname;
		&db_add_vertex($self, $dbh, $graph_id, $fname, $NV)
	    }
	} # END foreach my $line
    } # END foreach my $fn
}

sub __db_load_function_calls {
    my ($self, $dir, $dbh, $graph_id, $has_static_functions) = @_;    
    my ($u, $v);
    my $cflow_flags = "";
    my $cmd;
    my @sources;
    
    my ($version, $subsys) = split /\//, $dir;

    if ($has_static_functions == 0) {
	$cflow_flags .= " -i -s ";
    }

    @sources = &__get_source_files_list($dir);

    foreach my $fn (@sources) {
	$cmd = "\tcflow -b -d 2 ".$cflow_flags." $fn";
	print "$cmd" if $self->verbose;
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
	    } else  { # CALEE
		chomp $line;
		$line =~ m/\s+(\w+)\(\).*/;
		$v = $1;

		# If the function doesn't have subsystem, it will be ignored.
		if (!exists($Functions{$v})) {
		    $NOCTX++;
		    next LINE;
		    # keep here as alternative to be strict
		    #die "$v does not exists in subsystem table!\n";
		} else {
		    $v = $Functions{$v}.$PATH_SEPARATOR.$v;
		}
	    }
	    &db_add_arc($self, $dbh, $graph_id, $u, $v);
	}
    } # END_foreach my $fn...
}

1;
