#!/usr/bin/env python

import os, re
from graph_tool.all import *
from pylab import *

def generate_graph(dirname, verbose=True):
    # map function name to function vertices    
    func_vs = dict()
    # map the edge weight
    edge_weight = dict()
    
    G = Graph()
    vprop_name = G.new_vertex_property("string")
    eprop_weight = G.new_edge_property("int")    
    
    tokens = re.split("-", dirname)
    date = tokens[len(tokens)-3] + '-' \
           + '-' + tokens[len(tokens)-2] \
           + '-' + tokens[len(tokens)-1]
    
    filenames = os.listdir(dirname)
    i = 0
    for fn in filenames:
        i = i + 1
        sys.stdout.write(str(i) + '/' + str(len(filenames)) + ': ')

        print 'Processing', fn

        fn = dirname + '/' + fn
        f = open(fn, 'r')
        for line in f.readlines():
            v_dest = 0
            v_src = 0
            
            if line[0] == '#':
                continue

            if verbose:
                print '\n', line
            # A ftrace line is something like
            #<idle>-0     [000] d... 10648.607917: cpuidle_enter_state <-cpuidle_enter
            m = re.match(r'.*\s+\[(\d+)\]\s+[a-zA-Z0-9\.]{4}\s+(\d+\.\d+):\s+([\w\.]+)\s+\<\-([\w\.]+)', line)
            if m:
                cpu = int(m.group(1))
                timestamp = float(m.group(2))
                fdest = m.group(3)
                fsource = m.group(4)
            else:
                print 'ERROR: Problems parsing ftrace entry.'
                print '>>' + line + '<<'
                os.abort()

            # VERTEX
            if fdest in func_vs:
                v_dest = func_vs[fdest]                
            else:
                v = G.add_vertex()
                func_vs[fdest] = v
                v_dest = func_vs[fdest]
                vprop_name[v] = fdest
                                
            if fsource in func_vs:
                v_src = func_vs[fsource]                
            else:
                v = G.add_vertex()
                func_vs[fsource] = v
                v_src = func_vs[fsource]
                vprop_name[v] = fsource
                
            # EDGE
            # add edge only if it alredy new
            # we use a dictionary to map added edges
            # and its weight
            key = str(v_src) + '->' + str(v_dest)
            if key in edge_weight:
                e = edge_weight[key]
                eprop_weight[e] = eprop_weight[e] +  1
            else:
                e = G.add_edge(v_src, v_dest)
                edge_weight[key] = e
                eprop_weight[e] = 1

            if verbose:
                print 'G <-', 'E(', key , ' ', v_src, ',', v_dest, ',', eprop_weight[e] , ')'
                
            # verbosity is used to compare line and insertion in search of bugs
            if verbose:
                print '+', v_dest, '<-', v_src, cpu, timestamp, fdest, '<-', fsource

            f.close()

    G.vertex_properties["name"] = vprop_name
    G.edge_properties["weight"] = eprop_weight
    G.save(dirname + '.xml.gz')

    return G

def __load_graph(graphname):
    in_fn = graphname + '.xml.gz'
    G = load_graph(in_fn)
    print 'Loaded', in_fn

    return G

def plot_degree_distrib(graphname):
    G = __load_graph(graphname)
    
    in_hist = vertex_hist(G, "in")
    
    y = in_hist[0]
    err = sqrt(in_hist[0])
    err[err >= y] = y[err >= y] - 1e-2

    figure(figsize=(6,4))
    errorbar(in_hist[1][:-1], in_hist[0], fmt="o", yerr=err,
             label="in")
    gca().set_yscale("log")
    gca().set_xscale("log")
    gca().set_ylim(1e-1, 1e5)
    gca().set_xlim(0.8, 1e3)
    subplots_adjust(left=0.2, bottom=0.2)
    xlabel("$k_{in}$")
    ylabel("$NP(k_{in})$")
    tight_layout()
    savefig(graphname + '-deg-dist.pdf')
    savefig(graphname + '-deg-dist.png')

def filter_graph(G, filter_threshold):
    eprop_bet = G.new_edge_property("float") # NEW
    vprop_bet = G.new_vertex_property("float") # NEW
    eprop_weight = G.edge_properties["weight"] # already filled
    
    betweenness(G, vprop_bet, eprop_bet, eprop_weight)

    FG = Graph()
    F_eprop_weight = FG.new_edge_property("float")
    for e in G.edges():
        u = e.source()
        v = e.target()

        print e, eprop_bet[e]
        if eprop_bet[e] >= filter_threshold:
            f = FG.add_edge(u, v)
            F_eprop_weight[f] = eprop_weight[e]
            
    return FG
                
def draw_graph(graphname, filter_threshold=0.0):
    '''
    filter_threshold is a number from 0.0 to 1.0 to cut 
    vertices with value of betweenness less than it.
    '''    
    out_fn = graphname + ".pdf"

    G = __load_graph(graphname)

    deg = G.degree_property_map("in")
    deg.a = 4 * (sqrt(deg.a) * 0.5 + 0.4)
    eprop_weight = G.edge_properties["weight"]

    FG = filter_graph(G, filter_threshold)
    
    graph_draw(FG,
               pos=sfdp_layout(G),
               vertex_size=deg,
               vertex_fill_color=deg,
               vorder=deg,
               edge_color=eprop_weight,
#               edge_pen_width=eprop_weight,
 #              edge_control_points=eprop_weight,
               output=out_fn)

    print 'Output', out_fn

def save_to_graphviz_dot(graphname):
    out_fn = graphname + ".dot"

    G = __load_graph(graphname)

    vname = G.vertex_properties["name"]
    weight = G.edge_properties["weight"]

    max = 0
    for w in weight:
        if w > max:
            max = w
            
    f = open(out_fn, 'w')
    f.write('digraph {\n')
    for v in G.vertices():
        f.write('\t' + str(v) + ' [label=\"' + vname[v] + '\"];\n')

    f.write('\n')
    for e in G.edges():
        w = weight[e] / float(max)
        f.write('\t' + str(e.source()) + ' -> '
                + str(e.target())
                + ' [weight=\"' + str(w) + '\"];\n')
        
    f.write('}\n')
    f.close
    print 'Wrote', out_fn
    
if __name__ == '__main__':
    dirname = 'linux-4.4.0-2017-08-31'
#    G = generate_graph(dirname, False)
    plot_degree_distrib(dirname)
    draw_graph(dirname, 17e-3)
    save_to_graphviz_dot(dirname)
