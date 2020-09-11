#!/usr/bin/env python

import random as ra

# This script implements common methods of preferential attachment
# used by models. The adopted OOP mechanism is composition instead of
# inheritance. The class (model) interested in use this object may
# instantiate it and invoke the methods.
# The Graph G helps enforcing the needed abstraction by models.

class PrefAttach(object):        
        '''When a vertex v is added to a graph G, an edge links v with an
        existing vertex w with probablity proportional with w's degree.
        '''
        def __init__(self, G, in_is_pl=True, out_is_pl=True, verbose=False):
                '''Preferential attachment class constructor.
                
                Parameters
                ----------
                G - graph to store the vertices and arcs.
                is_power_law - the distribution is power law? Otherwise is treated
                as uniform.
                '''
                self.G = G
                self.dt2pl = {'in': in_is_pl, 'out': out_is_pl}
                self.verbose = verbose

        def choose_vertex(self, degree_type="in"):
                '''rank vertices according to its in or out degree and choose 
                one according to a probability.
                
                Parameters
                ----------
                degree_type : string in ['in', 'out']
                    'in' - vertex is chosen according to indegree distribution.
                    'out' - vertex is chosen according to outdegree distribution.
                '''
                total_deg = 0.0
                vs = []
                degs = []
                
                v2deg = self.G.get_vertices_sorted_by_degree(degree_type)

                # graph is empty create a vertex and return
                if v2deg == None:
                        return self.G.init_vertex()
                
                # calculate the total degree and accumulate v and degree
                for v, deg in v2deg.items():
                      total_deg = total_deg + deg                  
                      vs.append(v)
                      degs.append(deg)

                degs = sorted(degs, reverse=True)
                      
                # The vertices with greater degree have more probability
                # to be "chosen".
                p = ra.random()
                cum_prob = 0.0
                old_v = vs[0]
                N = len(vs)
                for i in range(N):
                        if self.dt2pl[degree_type] == True:
                                cum_prob = cum_prob + degs[i]/total_deg
                        else:
                                cum_prob = cum_prob + 1.0/N

                        # The verbosity is high to check two things:
                        # 1. the proper ordering of {in,out}degree
                        # 2. the right choice of vertex according to probability
                        if self.verbose == True:
                                print   '\t' + str(self.G.ident) + '.' +\
                                        str(vs[i])+',deg='+ str(degs[i]) +\
                                        ' cum_prob=' + str(cum_prob) + \
                                                     ' p=' + str(p)

                        if cum_prob > p:
                                if self.verbose == True:
                                        print '\tRETURN ' + str(old_v)
                                return old_v
                        old_v = vs[i]

                # here the probability takes the end of queue
                return vs[len(vs)-1]
        
        def source_vertex_step(self):
                '''source-vertex-step add a new vertex v and add an edge to an
                existing vertex w chosen according to indegree.
                '''
                v = self.G.init_vertex()
                w = self.choose_vertex("in")
                if self.verbose == True:
                        print 'source ' + str(v) +  ',' + str(w)
                self.G.add_edge(v, w)

        def sink_vertex_step(self):
                '''sink-vertex-step add a new vertex w and add an edge from an
                existing vertex v chosen according to outdegree.
                '''
                v = self.choose_vertex("out")
                w = self.G.init_vertex()
                if self.verbose == True:
                        print 'sink ' + str(v) +  ',' + str(w)
                self.G.add_edge(v, w)

        def edge_step(self):
                '''edge-step add a new edge from an existing vertex r to an existing
                vertex s.
                '''
                r = self.choose_vertex("out")
                s = self.choose_vertex("in")
                if self.verbose == True:
                        print 'edge ' + str(r) +  ',' + str(s)
                self.G.add_edge(r, s)


