#!/usr/bin/env python

import sys
import random as ra

# local modules
import pref_attach as pa
import graph

EPS = 1e-6

# Implement the directed scale-free graph model as described in the paper
# "Directed Scale-Free Graphs",
# Bela Bollobas, Christian Borgs, Jennifer Chayes, Oliver Riordan,
# Proceedings of the 14th Annual ACM-SIAM Symposium on Discrete Algorithms (SODA), pg 132-139, 2003.

class Bollobas:
        dbname = 'bollobas.db'
        
        def __init__(self, alpha, beta, gamma, graph_name, verbose=True):
                '''(A) With probability alpha, add a new vertex v together with an
                edge from v to an existing vertex w, where w is chosen according to
                din + delta_in
                (B) With probability beta, add an edge from an existing vertex v to
                an existing vertex w, where v and w are chosen independently, v
                according to d_out+delta_out , and w according to d_in+delta_in.
                (C) With probability gamma, add a new vertex w and an edge from an
                existing vertex v to w, where v is chosen according to
                d_out+delta_out.'''
                
                self.alpha = alpha
                self.beta = beta
                self.gamma = gamma
                self.verbose = verbose

                self.G = graph.Graph('wr', Bollobas.dbname, graph_name, self.verbose)
                self.pa = pa.PrefAttach(self.G)
                
                # maximum number of vertices of real graph to compare
                self.Glinux = graph.Graph('rd', 'linux.db', graph_name, self.verbose)
                self.max_nv = self.Glinux.no_vertices()
                
        def run(self):
                while True:
                        p = ra.random()
                        if p < self.alpha: # P_alpha
                                self.pa.source_vertex_step()
                        elif p < self.alpha + self.beta: # P_beta
                                self.pa.edge_step()
                        else: # P_gamma
                                self.pa.sink_vertex_step()

                        if self.G.no_vertices() >= self.max_nv:
                                break

                return self.G

def usage(pname):
        print pname + ''' --reset-db | [-v] -a <Probability-alpha> -b <Probability-beta> -c <Probability-gamma> -V <maximum-number-of-vertices> -n <graph-name> 
        Where
        \t -a <Probability-alpha>: With probability alpha, add a new vertex v together with an
        \t                         edge from v to an existing vertex w, where w is chosen 
        \t                         according to din + delta_in.

        \t -b <Probability-beta>: With probability beta, add an edge from an existing vertex v to
        \t                        an existing vertex w, where v and w are chosen independently, 
        \t                        v according to d_out+delta_out , and w according to d_in+delta_in.

        \t -c <Probability-gamma> With probability gamma, add a new vertex w and an edge from an
                                  existing vertex v to w, where v is chosen according to d_out+delta_out.

        \t <graph-name> name to store the graph in the sqlite3 database named \'bollobas.db\'.

        \t --reset-db remove database file, if it exists, and create all tables.
        
        \t -v (optional) verbose. Important: put the flag -v at the beginning of the flags set.'''
        exit(-1)
        
if __name__=='__main__':
        verbose = True
        (a, b, c) = (0.0, 0.0, 0.0)
        max_nv = 0
        graph_name = ''

        if len(sys.argv) == 2:
                if len(sys.argv) == 2 and sys.argv[1] == '--reset-db':
                        graph.Graph.drop_and_create_tables(Bollobas.dbname)
                        exit(1)

        if len(sys.argv) == 8 or len(sys.argv) == 9:
                for i in range(len(sys.argv)):
                        if sys.argv[i] == '-v':
                                verbose=True

                        if sys.argv[i] == '-a':
                                a = float(sys.argv[i+1])
                        if sys.argv[i] == '-b':
                                b = float(sys.argv[i+1])
                        if sys.argv[i] == '-c':
                                c = float(sys.argv[i+1])
                        if i == len(sys.argv)-1:
                                graph_name = sys.argv[i+1]

        u=a+b+c
        if u > (1.0+EPS) or u < (1.0-EPS):
                print u
                print 'a+b+c must be equal 1.0'
                exit(-1)
        if max_nv <= 0:
                print 'number of vertices must be greater than zero.'
                exit(-1)
                        
        bo = Bollobas(a, b, c, graph_name, verbose)
        bo.run()
        print 'Summary:'
        print 'graph:', graph_name
        print 'linux: {} vertices, {} arcs'.format(bo.Glinux.no_vertices(), bo.Glinux.no_arcs())
        print 'bollobas: {} vertices, {} arcs'.format(G.no_vertices(), G.no_arcs())
        print 'a={}, b={}, c={}'.format(bo.alpha, bo.beta, bo.gamma)

