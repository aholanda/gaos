#!/usr/bin/env perl

# Generate directed graph using preferential attachment model
# described in the page 70 of the book "Complex Graphs and Networks"
# by Chung and Lu.

use strict;

my $TMPDIR = "/tmp/";
my $PROJ = "pref_attach";

my @deg_ts = ("in", "out"); # degree types

my $VERBOSE = 1;

my $SELF_EDGES = 0;
my $NSE = 0; # number of self edges

my $EPS = 0.00000000001; # to avoid division by zero 
my $EDGE = "->"; # edge link
my $NV = 0; # vertex counter
my %v2degree; # hash of hash, map vertex id to degree ( "in", "out")
my $total_degree = $EPS; # total degree = number of edges
my %G; # store edges and their weights

&main();

sub main{
    # we start with 1->2 edge to avoid void graph problems, division by
    # zero during first calculation of probabilities
    &add_edge(&init_vertex(), &init_vertex()); 

    #&ba(31, 36);

    &chung_lu(0.5, 0.2, .75, 0.0, 1170);
}

sub write_summary {
    print STDERR "Summary:\n";
    print STDERR "    #vertices: $NV\n";
    print STDERR "    #edges: $total_degree\n";
    print STDERR "    #total-degree(in|out): ".$total_degree."\n";
    print STDERR "    #self-edges: $NSE\n";
}

sub write_dot {
    my $fn = $TMPDIR.$PROJ.".dot";

    open(DOT, ">$fn") or die "Could not open $fn\n";
    print DOT "digraph g {\n";
    foreach my $e (keys %G) {
	my $w = $G{$e};
	$e =~ m/(\d+)$EDGE(\d+)/;
	my $u = $1;
	my $v = $2;

	print DOT "\t $u $EDGE $v [weight=$w];\n";
    }
    print DOT "}\n";
    close(DOT);
    print STDERR "Wrote $fn\n";
}

sub init_vertex {
    my $v = ++$NV;

    $v2degree{"in"}{$v} = $EPS;
    $v2degree{"out"}{$v} = $EPS;

    if ($VERBOSE) {
	my $ne = $total_degree;
	print STDERR "\tinit(v): $v\tindeg=".$v2degree{"in"}{$v}."/$ne\toutdeg=".$v2degree{"out"}{$v}."/$ne\n";
    }    
    return $v;
}

sub add_edge {
    my $u = shift;
    my $v = shift;
    my $e;
    
    if ($u < 0 || $v < 0) {
	die "ERROR: wrong index to vertex u=$u or v=$v\n";
    }

    if ($u == $v) {
	if (!$SELF_EDGES) {
	    return;
	} else {
	    $NSE++;
	}
    }

    $e = $u."->".$v;
    
    print STDERR "\tadd_edge: ".$e."\n";
    
    $v2degree{"out"}{$u}++;
    $v2degree{"in"}{$v}++;
    $total_degree++;

    if (exists($G{$e})) {
	$G{$e}++;
    } else {
	$G{$e} = 1;
    }
}

# Choose vertex in proportion to {in,out}degree.
sub choose_vertex {
    my $deg_type = shift; # in- or out-degree
    my $pr_plaw = shift; #  probability to occur power law distribution
    my $pr_uniform = shift; # probability to occur uniform distribution
    
    my $cum_prob = 0.0; # cummulative probabilty
    my $i = 0; # counter for the hash loop, i am not trusting in vertex id

    return if $NV == 0; # empty graph
    
    my $p_dist = rand(); # 
    
    my $p = rand();
    
    my $old_v = -1;
    if ($p_dist <= $pr_plaw) { # power law distribution
	foreach my $v (sort { $v2degree{$deg_type}{$b} <=> $v2degree{$deg_type}{$a} } keys %{ $v2degree{$deg_type} }) { # sort hash by value
	    $i++;
	    my $deg = $v2degree{$deg_type}{$v};
	    
	    
	    $cum_prob += $deg / $total_degree;	
	    print STDERR "\t POWER LAW choosing vertex: rand=$p\tv=$v/$NV\tdeg=$deg\tcum_prob=$cum_prob\n" if $VERBOSE;
	    
	    # when cumulative probability pass random number value, old v index
	    # is the vertex in the degree proportion. If there is only one element
	    # in the hash $old_v must be assigned to that element. We do that by
	    # verifying loop counter $i.
	    if ($cum_prob > $p && $i > 1) {
		last;
	    }	
	    $old_v = $v;
	} # END_foreach_my_$v
    } else { # uniform distribution
	foreach my $v ( keys %{ $v2degree{$deg_type} }) { # 
	    $i++;
	    $cum_prob = $i /$NV;
	    print STDERR "\t UNIFORM choosing vertex: rand=$p\tv=$v/$NV\ti=$i\tcum_prob=$cum_prob\n" if $VERBOSE;
	    if ($cum_prob > $p && $i > 1) {
		last;
	    }	
	    $old_v = $v;
	}
    }
    return $old_v;    
}

# Source-vertex-step - Add a new vertex v, and add a directed edge
# (v,w) from v by randomly and independently choosing w in proportion
# to the indegree of w in the current graph G.
sub source_vertex_step {
    my $pr_plaw = shift; #  probability to occur power law distribution
    my $pr_uniform = shift; # probability to occur uniform probability

    print STDERR "Source-vertex-step\n" if $VERBOSE;
    
    my $v = &init_vertex();

    my $w = &choose_vertex("in", $pr_plaw, $pr_uniform);

    &add_edge($v, $w, $pr_plaw, $pr_uniform);
}

# Sink-vertex-step - Add a new vertex v, and add a directed edge (u,v)
# to v by randomly and independently choosing u in proportion to the
# outdegree of u in the current graph G.
sub sink_vertex_step {
    print STDERR "Sink-vertex-step\n" if $VERBOSE;
    my $pr_plaw = shift; #  probability to occur power law distribution
    my $pr_uniform = shift; # probability to occur uniform probability
    
    my $v = &init_vertex();

    my $u = &choose_vertex("out", $pr_plaw, $pr_uniform);

    &add_edge($u, $v, $pr_plaw, $pr_uniform);
}

# Edge-step - Add a new edge (r,s) by indenpendently choosing vertices
# r and s with probability proportional to outdegree (respectively
# indegree).
sub edge_step {
    my $pr_plaw = shift; #  probability to occur power law distribution
    my $pr_uniform = shift; # probability to occur uniform probability
    print STDERR "Edge-step\n" if $VERBOSE;
    
    my $r = -1;
    my $s = -1;
    
    print STDERR "r>\n" if $VERBOSE;
    $r = &choose_vertex("out", $pr_plaw, $pr_uniform);

    print STDERR "s<\n" if $VERBOSE;    
    $s = &choose_vertex("in", $pr_plaw, $pr_uniform);

    &add_edge($r, $s, $pr_plaw, $pr_uniform);
}

# cumulative degree distributions
sub cum_degree_distrib {
    my %freq; # hash of hash ( "in|out" => degree => degree frequence )
    
    foreach my $t (@deg_ts) {
	my %freq;
	
	foreach my $v ( keys %{ $v2degree{$t} }) {
	    my $deg = $v2degree{$t}{$v};

	    if ($deg == $EPS) {
		next;
	    }
	    
	    if (exists($freq{$deg})) {
		$freq{$deg}++;
	    } else {
		$freq{$deg} = 1;
	    }
	}

	# write output
	my $cum_prob = 0.0;
	my $fn = "/tmp/$t-pref_attach.dat";
	open(OUT, ">$fn");	
	foreach my $deg (sort { $freq{$a} <=> $freq{$b} } keys %freq) {
	    $cum_prob += $freq{$deg} / $NV;

	    print STDERR "$deg\t".$freq{$deg}."\n";
	    print OUT "$deg\t$cum_prob\n";
	}
	close(OUT);
	print STDERR "Wrote $fn\n";
    }
}

# Taken from "Complex Graphs and Networks" book by Chung and Lu
sub chung_lu {
    my ($Pr1, $Pr2, $Pr_PL, $Pr_Unif, $MAX_NV) = @_; # p1, p2, Pr(power law), Pr(uniform), max number of vertices
    
    if ($Pr1 + $Pr2 > 1.0) {# p1 +p2 <=1
	die "ERROR: p1=$Pr1 + p2=$Pr2 must be <= 1.0\n";
    }

    if ($Pr_PL + $Pr_Unif > 1.0) {
	die "ERROR: Pr(Power Law Distribution)=$Pr1 + Pr(Uniform Distribution)=$Pr2 must be <= 1.0\n";
    }

    while (1) {
	# with probability p1, take source-vertex-step
	if ($Pr1 > rand()) {
	    &source_vertex_step($Pr_PL, $Pr_Unif);
	}

	# with probability p2, take sink-vertex-step
	if ($Pr2 > rand()) {
	    &sink_vertex_step($Pr_PL, $Pr_Unif);
	} else {# otherwise edge-step
	    &edge_step($Pr_PL, $Pr_Unif); 
	}
	
	last if $NV > $MAX_NV;
    }

    &write_summary();

    &cum_degree_distrib();

    &write_dot();

}

# Barabasi-Albert model
sub ba {
    my $nv = shift; # number of vertives
    my $ne = shift; # number of arcs/edges

    while ($NV<=$nv) {
	&source_vertex_step();
    }

    while ($total_degree<=$ne) {
	&edge_step();
    }

    &write_summary();

    &cum_degree_distrib();

    &write_dot();
}
