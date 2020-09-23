#!/usr/bin/env python
from __future__ import generators

import numpy as np

# local
import graph

# class to emulate constants in python
class CONST(object):
        DBNAME = 'linux.db' # SQLite database
        DEFAULT_VERSION = '4.14.14' # more recent stable linux version
        DEFAULT_SUBSYS = 'kernel' # main subsystem

        def __setattr__(self, *_):
                pass

CONST = CONST()

def flush_degrees(version, subsys, verbose=False):
        '''Write vertex (function) degrees according to subsystem.'''

        graph_name = 'linux-' + version
        degree_types = ['out', 'in']
        idx = {'out': 0, 'in': 1}

        for dt in degree_types:
                subsyss = ['', '']
                funcs = ['', '']
                vs = ['', '']
                
                fn = dt + 'deg-vals-'+ graph_name + '-' + subsys + '.csv'
                f = open(fn, 'w')
        
                G = graph.Graph('rd', CONST.DBNAME, graph_name, 0)
                N = G.no_vertices()
                M = G.no_arcs()
                v2deg = {}
                n = 0
                        
                # Get arcs and their weights
                # write degrees to a file to fit the curve
                G.write_arcs('/tmp/arcs.txt')
                fa = open('/tmp/arcs.txt', 'r')
                for ln in fa.readlines():
                        vs = ln.rstrip().split(graph.Graph.ARC_SYMBOL)
                        vs[0] = G.get_vertex_name_by_id(vs[0])
                        vs[1] = G.get_vertex_name_by_id(vs[1])
                        subsyss[0], funcs[0] = vs[0].split(".")
                        subsyss[1], funcs[1] = vs[1].split(".")

                        if subsyss[idx[dt]] != subsys:
                                continue

                        if verbose:
                                print '\t', vs[0], '->', vs[1]
                                
                        n += 1

                        # hash vertex according to its degree
                        if v2deg.has_key(vs[idx[dt]]):
                                v2deg[vs[idx[dt]]] += 1
                        else:
                                v2deg[vs[idx[dt]]] = 1
                                                
                for v, deg in v2deg.items():
                        f.write(str(deg) + '\n')

                # Fill with zeros the vertices that have no degrees
                # this procedures allows the probability be calculated
                # properly.
                for x in range(N-n):
                        f.write(str(0) + '\n')

                fa.close()
                f.close()
                print 'Wrote values in \'' + fn + '\''

def usage(prgname):
        print prgname + ' [SUBSYSTEM] [VERSION]'
        print 'WHERE'
        print '\tSUBSYSTEM (optional) - is the name of the linux subsystem to be processed. [DEFAULT: ' + CONST.DEFAULT_SUBSYS + ']'
        print '\tVERSION (optional) - is the linux version to be processed. [DEFAULT: ' + CONST.DEFAULT_VERSION + ']'
        print '\teg. $ ' + prgname + ' ipc 1.0      # flush degrees for ipc subsystem of linux-1.0'
        print 'This script writes the vertex (linux function) degrees, one per line, in a file.'
        exit(-1)
        
import sys
if __name__ == '__main__':
        version = CONST.DEFAULT_VERSION
        subsys = CONST.DEFAULT_SUBSYS
        
        if len(sys.argv) == 1:
                print 'Running using default arguments: subsystem=' + subsys + ', version=' + version
        elif len(sys.argv) == 2:
                subsys = sys.argv[1]

                if subsys == '-h':
                        usage(sys.argv[0])

        elif len(sys.argv) == 3:
                subsys = sys.argv[1]
                version = sys.argv[2]
        else:
                usage(sys.argv[0])

        flush_degrees(version, subsys, True)
