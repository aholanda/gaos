#--write-circos-conf <linux-dir>: write the files <linux-dir>-circos.conf, <linux-dir>-ideogram.conf,
#<linux-dir>-links.conf, <linux-dir>-endlinks.conf. All these files are needed to run circos.

# COLORS to write ideogram piece of subsystem
my %Colors = (
    "arch" => "gray",
    "block" => "lorange",
    "crypto" => "yellow",
    "drivers" => "red",
    "init" => "black",
    "ipc" => "black",
    "kernel" => "green",
    "lib" => "gray",
    "mm" => "orange",
    "net" => "blue",
    "sound" => "brown",
    "tools" => "lgreen",
    "virt" => "yellow",
    "zfs" => "dorange",
    );

my $CIRCOS = '/local/circos-0.69-6/bin/circos';


sub write_circos_files {
    my $dir = shift;    

    write_circos_ideogram($dir);
    write_circos_links($dir);
    write_circos_conf($dir);
}

sub run_circos {
    my $prefix = shift;

    my $cmd = "$CIRCOS -conf $prefix-circos.conf -debug_group summary,timer >/tmp/circos.log";
    print "$cmd\n";
    `$cmd`;
    print "Warn: to clean files, run 'make clean'\n";
}

sub write_circos_ideogram {
    my $dir = shift;
    
    my $fn = $dir."-ideogram.txt";
    open(OUT, ">$fn");    
    foreach my $key (keys %Subsys) {
	my $nfuncs = $Subsys{$key};
	my $color = "gray";
	
	if (exists($Colors{$key})) {
	    $color = $Colors{$key};
	} 
	
	if ($nfuncs > $MIN_FUNCTIONS) {
	    print OUT "chr - ".$key."\t\t".$key. "\t0\t".$nfuncs."\t". $color  ."\n";
	}
    }
    close(OUT);
    print STDERR "Wrote $fn\n";
}

sub write_circos_links {
    my $dir = shift;

    my $fn0 = $dir."-links.txt";
    # endlinks is where the tips of arcs are set
    my $fn1 = $dir."-endlinks.txt";
    open(OUT0, ">$fn0");
    open(OUT1, ">$fn1");    

    my $c = 0;
  KEY:
    foreach my $key (keys %Edges) {
	$c++;	

	# if ($c % 2 == 0) { # TODO: do a better filter
	#     next KEY;
	# }

	my ($uu, $vv) = split /$EDGE_LINK/, $key;
	

	my ($v_subsys, $v) = split /\./, $vv;
	my ($u_subsys, $u) = split /\./, $uu;

	if ($u_subsys eq $v_subsys) {
	    next KEY;
	}
	
	my $u_coord = $Coords{$u_subsys}{$u};
	my $v_coord = $Coords{$v_subsys}{$v};

	# we print the direction v <- u
	print OUT0 "$v_subsys $v_coord $v_coord $u_subsys $u_coord $u_coord\n";	    

	# According to circos syntax we print only the arc tip
	# coordinates in a separate file, we use modulo to emulate
	# that.
	print OUT1 "$v_subsys $v_coord $v_coord 0\n";
    }
    close(OUT0);
    print STDERR "Wrote $fn0\n";
    close(OUT1);
    print STDERR "Wrote $fn1\n";
    print STDERR  "$V nodes processed\n";
    print STDERR  "$c edges processed\n";
}

sub write_circos_conf {
    my $dir = shift;
    
    my $fn = $dir."-circos.conf";
    
    my $circos_conf = <<"CIRCOS_CONF";
karyotype = $dir-ideogram.txt

<links>

<link>
file          = $dir-links.txt
radius        = 0.95r
color         = black_a4

# Curves look best when this value is small (e.g. 0.1r or 0r)
bezier_radius = 0.1r
thickness     = 2

# These parameters have default values. To unset them
# use 'undef'
#crest                = undef
#bezier_radius_purity = undef

# Limit how many links to read from file and draw
record_limit  = 2000

</link>

</links>

<ideogram>
show = yes

<spacing>
default = 0.005r
</spacing>

radius = .8r
thickness = 20p
stroke_thickness = 2
# ideogram border color
stroke_color     = black
fill = yes

show_label = yes

label_font = default
label_radius = 1.08r
label_size = 80
label_parallel = no

show_bands = yes
fill_bands = yes

</ideogram>

<plots>
<plot>
type  = scatter
file  = $dir-endlinks.txt
glyph      = triangle
glyph_size = 24p

min = 0
max = 1
r0  = 0.99r
r1  = 0.99r
fill_color = black

#<rules>
#<rule>
#condition  = 1
#fill_color = eval(lc "chr".substr(var(chr),2))
#</rule>
# </rules>

</plot>
</plots>

<image>
dir   = .
file  = $dir-circos.png
24bit = yes
radius         = 1500p
background     = white
angle_offset   = -90
auto_alpha_colors = yes
auto_alpha_steps  = 5
</image>

<<include etc/colors_fonts_patterns.conf>>
<<include etc/housekeeping.conf>>
data_out_of_range* = trim

# BANDS
show_bands            = yes
fill_bands            = yes
band_stroke_thickness = 2
band_stroke_color     = white
band_transparency     = 0

# TICKS
show_ticks          = yes
show_tick_labels    = yes

<ticks>
radius               = dims(ideogram,radius_outer)
multiplier           = 1e-6

label_offset = 5p
thickness = 3p
size      = 20p

# ticks must be separated by 2 pixels in order
# to be displayed
tick_separation      = 2p

# Density of labels is independently controlled.
# While all tick sets have labels, only labels
# no closer than 5 pixels to nearest label will be drawn
label_separation     = 5p

<tick>
spacing        = 0.5u
color          = red
show_label     = yes
label_size     = 14p
label_offset   = 0p
format         = %.1f
</tick>

<tick>
spacing        = 1u
color          = blue
show_label     = yes
label_size     = 16p
label_offset   = 0p
format         = %d
</tick>

<tick>
spacing        = 5u
color          = green
show_label     = yes
label_size     = 20p
label_offset   = 0p
format         = %d
</tick>

<tick>
spacing        = 10u
color          = black
show_label     = yes
label_size     = 24p
label_offset   = 5p
format         = %d
</tick>

</ticks>

CIRCOS_CONF

open(OUT, ">$fn");
print OUT $circos_conf;
close(OUT);
print STDERR "Wrote $fn\n";
}
