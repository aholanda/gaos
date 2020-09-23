#!/usr/bin/env python

# Calculate centralities using SNAP library

import graph_tool.centrality
import networkx as nx

# local

import graph

DBNAME = 'linux.db'
SEP = ','

def nx_write_values(G, fn, nodes):
        f = open(fn, 'w')
        for n,val in nodes.items():
                print n,val
                if val > 0.0:
                        f.write(G.nodes[n]['name'] + SEP + str(val) + '\n')
        f.close()
        print 'Wrote', fn

def gt_write_values(g, fn, props):
        f = open(fn, 'w')
        vprop_name = g.vertex_properties['name']
        for i in range(g.num_vertices()):
                val = props[i]
                print vprop_name[i], val
                if val > 0.0:
                        f.write(vprop_name[i] + SEP + str(val) + '\n')
        f.close()
        print 'Wrote', fn

if __name__ == '__main__':
        graph_names = graph.Graph.get_graph_names(DBNAME, 0)
        for gn in graph_names:
                g = graph.Graph('rd', DBNAME, gn, 0)
                G_gt = g.to_graph_tool()
                G_nx = g.to_networkx_graph()
                
                # PAGERANK
                props = graph_tool.centrality.pagerank(G_gt)
                fn = 'pagerank.centr.' + gn + '.csv'
                gt_write_values(G_gt, fn, props)

                # INDEGREE
                nodes = nx.in_degree_centrality(G_nx)
                fn = 'indeg.centr.' + gn + '.csv'
                nx_write_values(G_nx, fn, nodes)

                # OUTDEGREE
                nodes = nx.in_degree_centrality(G_nx)
                fn = 'outdeg.centr.' + gn + '.csv'
                nx_write_values(G_nx, fn, nodes)
                
                # BETWEENNESS
                nodes = nx.betweenness_centrality(G_nx, None, True, 'weight')
                fn = 'bet.centr.' + gn + '.csv'
                nx_write_values(G_nx, fn, nodes)
                
                # CLOSENESS
                fn = 'close.centr.' + gn + '.csv'
                nodes = nx.closeness_centrality(G_nx)
                nx_write_values(G_nx, fn, nodes)

                # # EIGENVECTOR
                # fn = 'eigen.centr.' + gn + '.csv'
                # nodes = nx.eigenvector_centrality(G, 10000, 1e-5, None, weight='weight')
                # __write_values(g, fn, nodes)
                
