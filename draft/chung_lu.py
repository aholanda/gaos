#!/usr/bin/env python

# This script implements Modular Chung-Lu Preferential Attachment
# simulation

import math
import random as ra
import sys

# local
import graph
import pref_attach as pa

class ChungLu:
        dbname = 'chung_lu.db'
        
        def __init__(self, p1, p2, graph_name, verbose=False):
                self.p1 = p1 # probability of source vertex
                self.p2 = p2 # probability of sink vertex
                self.verbose = verbose

                self.G = graph.Graph('wr', ChungLu.dbname, graph_name, 0, self.verbose)
                self.pa = pa.PrefAttach(self.G)
                
                # maximum number of vertices of real graph to compare
                self.Glinux = graph.Graph('rd', 'linux.db', graph_name, 0, self.verbose)
                self.max_nv = self.Glinux.no_vertices()
                
        def run(self):
                while True:
                        p = ra.random()
                        # with probability p1, take source-vertex-step
	                if p < self.p1:
	                        self.pa.source_vertex_step()
	                # with probability p2, take sink-vertex-step
	                elif p < self.p1 + self.p2:
	                        self.pa.sink_vertex_step()
                        else: # otherwise edge-step
	                        self.pa.edge_step(); 

                        # the running stops when the number of vertices
                        # of the model is equal to the real graph
	                if self.G.no_vertices() >= self.max_nv:
                                break
                return self.G

def usage(pname):
        print pname + ''' --reset-db | [-v] -p1 <source-probability-> -p2 <sink-probability-beta> <graph-name>
        Where:
        \t -p1 <source-probability>  Source-vertex-step - Add a new vertex v, and add a directed edge (v, w)
        \t                           from v by randomly and independently choosing w in proportion to the
        \t                           indegree of w in the current graph .
        
        \t -p2 <sink-probability>    Sink-vertex-step - Add a new vertex v, and add a directed edge (u, v) to v
        \t                           by randomly and independently choosing u in proportion to the outdegree
        \t                           of u in the current graph.
        
        \t <graph-name> name to store the graph in the sqlite3 database named \'chung_lu.db\'.
        
        \t --reset-db remove database file, if it exists, and create all tables.
        
        \t -v (optional) verbose.'''
        exit(-1)

if __name__=='__main__':
        verbose = False
        (p1, p2) = (0.0, 0.0)
        graph_name = None
        flags_ok = [False, False]
        
        if len(sys.argv) == 2:
                if sys.argv[1] == '--reset-db':
                        graph.Graph.drop_and_create_tables(ChungLu.dbname)
                        exit(1)

        if len(sys.argv) == 6 or len(sys.argv) == 7:
                for i in range(len(sys.argv)):
                        if sys.argv[i] == '-v':
                                verbose=True

                        if sys.argv[i] == '-p1':
                                p1 = float(sys.argv[i+1])
                                flags_ok[0] = True
                        if sys.argv[i] == '-p2':
                                p2 = float(sys.argv[i+1])
                                flags_ok[1] = True
                        if i == len(sys.argv)-1:
                                graph_name = sys.argv[i]                                

        # Constraints
        if p1 < 0.0 or p2 < 0.0 or (p1+p2) > 1.0:
                print 'ERROR: expected 0.0 <= p1,p2 <= p1+p2 <= 1.0, p1={}, p2={}, p1+p2={}'.format(p1, p2, p1+p2)
                exit(-1)
                
        for ok in flags_ok:
                if ok == False:
                        usage(sys.argv[0])

        cl = ChungLu(p1, p2, graph_name, verbose)
        G = cl.run()
        print 'Summary:'
        print 'graph:', graph_name
        print 'linux: {} vertices, {} arcs'.format(cl.Glinux.no_vertices(), cl.Glinux.no_arcs())
        print 'chung_lu: {} vertices, {} arcs'.format(G.no_vertices(), G.no_arcs())
        print 'p1={}, p2={}'.format(cl.p1, cl.p2)
        
