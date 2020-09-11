#!/usr/bin/env python
from __future__ import generators  

import os
import sqlite3
import sys

# graph libraries
import snap
import networkx as nx
import graph_tool as gt

attr = {'in' : 'to_id', 'out' : 'from_id'}

class Graph:
        ARC_SYMBOL = '>'
        
        tbls = ['arc', 'vertex', 'graph']                

        # true if the graph has static functions
        func = ['NO', 'YES']
        
        @classmethod
        def create_tables(cls, dbname):
                db = sqlite3.connect(dbname)
                cursor = db.cursor()
                f = open('graph.sql', 'r')
                for sql in f.xreadlines():
                        print sql
                        cursor.execute(sql)
                db.commit()
                f.close()

        @classmethod
        def list_graphs(cls, dbname, has_static_function=0):
                db = sqlite3.connect(dbname)
                cursor = db.cursor()
                cursor.execute('SELECT id, name, has_static_function FROM graph WHERE has_static_function=? ORDER BY name',
                               (has_static_function,))
                rows = cursor.fetchall()
                print 'Graphs:'
                print 'Id\tName\tHas static function?'
                for row in rows:
                        print row[0],'\t',row[1],'\t', cls.func[row[2]]

        @classmethod
        def get_graph_names(cls, dbname, has_static_function=0):
                names = []
                
                db = sqlite3.connect(dbname)
                cursor = db.cursor()
                cursor.execute('SELECT name FROM graph WHERE has_static_function=? ORDER BY name',
                               (has_static_function,))
                rows = cursor.fetchall()
                for row in rows:
                        names.append(row[0])

                return names
                        
        @classmethod
        def drop_and_create_tables(cls, dbname):
                print 'removing ' + dbname
                os.remove(dbname)
                cls.create_tables(dbname)
                
        def __init__(self, op, dbname, graph_name, has_static_function=0, verbose=False):
                self.op = op
                self.dbname = dbname
                self.name = graph_name
                self.has_static_function = has_static_function
                self.verbose = verbose
                # insert graph info and get id
                self.db = sqlite3.connect(dbname)
                cursor = self.db.cursor()

                if self.op == 'rd': # read
                        cursor.execute('SELECT id FROM graph WHERE name=? AND has_static_function=?',
                                       (self.name,self.has_static_function))
                        row = cursor.fetchone()
                        if row == None:
                                print self.name + ' with has_static_function='+ \
                                                Graph.func[self.has_static_function]  \
                                                +' does not exist in database ' + dbname
                                exit(-1)
                        else:
                                self.ident = row[0]
                elif self.op == 'wr':
                        self.NV = 0 # number of vertices
                        
                        cursor.execute('INSERT INTO graph(name,has_static_function) VALUES(?,?)',
                                       (self.name,self.has_static_function))
                        self.ident = cursor.lastrowid
                        self.db.commit()
                else:
                        'Operation not recognized: ' + op
                        
        def no_vertices(self):
                if self.op == 'rd':
                        cursor = self.db.cursor()
                        cursor.execute('SELECT COUNT(V.id) FROM vertex AS V, graph AS G WHERE G.id=V.graph_id AND graph_id=? AND G.has_static_function=?',(self.ident,self.has_static_function,))
                        count = cursor.fetchone()
                
                        return count[0]
        
        def no_arcs(self):
                if self.op == 'rd':
                        cursor = self.db.cursor()
                        cursor.execute('SELECT COUNT(A.from_id) FROM arc AS A, graph AS G WHERE G.id=A.graph_id AND A.graph_id=?', (self.ident,))
                        count = cursor.fetchone()
                
                        return count[0]
        
        def init_vertex(self):
                if self.op == 'wr':
                        self.NV = self.NV + 1
                        
                        cursor = self.db.cursor()
                        cursor.execute('INSERT INTO vertex(graph_id,id,name) VALUES(?,?,?)', (self.ident,self.NV,str(self.NV),))
                        self.db.commit()

                        return cursor.lastrowid

        def get_vertex_name_by_id(self, vertex_id):
                cursor = self.db.cursor()
                cursor.execute('SELECT V.name FROM vertex AS V, graph AS G WHERE V.graph_id=G.id AND V.id=? AND V.graph_id=? AND G.has_static_function=?', (vertex_id,self.ident,self.has_static_function,))
                count = cursor.fetchone()

                return count[0]
                
        def get_vertices_sorted_by_degree(self, degree_type='in'):
                ''' 'in' for indegree or 'out' for outdegree
                     return a dictionary with vertices and its 
                     degrees and the sum of degrees.
                '''
                v2deg = {}
                
                # arc attribute to map labels "in" and "out"
                sql = 'SELECT ' + attr[degree_type]   + ',' \
                ' COUNT(' + attr[degree_type] + ') AS FREQ ' + \
                ' FROM arc AS A, vertex AS V, graph as G ' +\
                ' WHERE G.id=V.graph_id AND G.id=A.graph_id AND ' +\
                 ' V.id=A.' + attr[degree_type] + \
                        ' AND G.name=?' + \
                        ' GROUP BY ' + attr[degree_type] + \
                        ' ORDER BY FREQ DESC '

                if self.verbose == True:
                        print '\t' + sql
                # get sorted vertices
                cursor = self.db.cursor()
                cursor.execute(sql,(self.name,))
                rows = cursor.fetchall()

                if len(rows) == 0:
                        return None
                
                # choose a vertex based on its degree
                for row in rows:
                        (v, deg) = row
                        v2deg[v] = deg

                return v2deg

        def write_arcs(self, filename):
                sql = 'SELECT from_id, to_id, weight ' \
                ' FROM arc AS A, vertex AS V, graph as G ' +\
                ' WHERE G.id=V.graph_id AND G.id=A.graph_id AND ' +\
                 ' V.id=A.from_id AND G.NAME=?'

                f = open(filename, 'w')
                
                if self.verbose == True:
                        print '\t' + sql

                cursor = self.db.cursor()
                cursor.execute(sql,(self.name,))
                rows = cursor.fetchall()
                if rows:
                        for row in rows:
                                f.write(str(row[0]) + Graph.ARC_SYMBOL + str(row[1]) + Graph.ARC_SYMBOL + str(row[2]) + '\n')
                
                f.close()
        
        
        def add_edge(self, u, v, w=1.0):
                '''add edge u->v to table arc in the database. First, verify if the
                arc already exists. If not, insert it with weight equal to 1. If it
                exists, the arc weight is incremented by one.'''
                if self.op == 'wr':
                        cursor = self.db.cursor()

                        cursor.execute('SELECT weight FROM arc WHERE graph_id=? AND from_id=? AND to_id=?', (self.ident,u,v,))
                        row = cursor.fetchone()
                        if row == None:
                                cursor.execute('INSERT INTO arc(graph_id, from_id, to_id, weight) VALUES(?,?,?,?)', (self.ident,u,v,w,))
                        else:
                                w = float(row[0] + w) # weight
                                cursor.execute('UPDATE arc SET weight=? WHERE graph_id=? AND from_id=? AND to_id=?', (w,self.ident,u,v,))

        def get_vertices(self):
                '''Return a array of tuples (u,n) where u is the vertex, 
                n is the vertex name.'''
                vs = []
                
                cursor = self.db.cursor()
                cursor.execute('SELECT id, name FROM vertex WHERE graph_id=?', (self.ident,))
                rows = cursor.fetchall()
                for row in rows:
                        vs.append((row[0], row[1]))

                return vs

                                
        def get_edges(self):
                '''Return a array of tuples (u,v,w) where u is the source vertex, 
                v is the destination vertex and w is the arc weight.'''
                es = []
                
                cursor = self.db.cursor()
                cursor.execute('SELECT from_id, to_id, weight FROM arc WHERE graph_id=?', (self.ident,))
                rows = cursor.fetchall()
                for row in rows:
                        es.append((row[0], row[1], row[2]))

                return es
        
        def to_snap_graph(self):
                '''Convert the graph to SNAP graph structure.'''                
                if self.op == 'wr':
                        return None

                # create a directed network
                N = snap.TDirNet.New()
                                
                cursor = self.db.cursor()
                cursor.execute('SELECT from_id, to_id, weight FROM arc WHERE graph_id=?', (self.ident,))
                rows = cursor.fetchall()
                for row in rows:
                        vs = [row[0], row[1]]
                        for v in vs:
                                if N.IsNode(v) == False:
                                        N.AddNode(v)
                        N.AddEdge(vs[0], vs[1])

                return N

        def to_networkx_graph(self):
                '''Convert the graph to SNAP graph structure.'''                
                if self.op == 'wr':
                        return None

                # create a directed network
                D = nx.DiGraph()

                # ADD VERTICES
                vs = self.get_vertices()
                for i,n in vs:
                        D.add_node(i, name=n)

                # ADD ARCS
                es = self.get_edges()
                for u, v, w in es:
                       D.add_edge(u, v, weight=w)

                return D

        def to_graph_tool(self):
                '''Return a graph structure converted to graph-tool.'''
                if self.op == 'wr':
                        return None

                ids = {}

                # CREATE DIGRAPH
                D = gt.Graph(directed=True)

                # ADD VERTICES
                vprop_name = D.new_vertex_property("string")
                D.vertex_properties['name'] = vprop_name
                vs = self.get_vertices()
                for i,n in vs:
                        v = D.add_vertex()
                        ids[i] = v
                        vprop_name[v] = n

                # ADD ARCS
                eprop_weight = D.new_edge_property("float")
                D.edge_properties['weight'] = eprop_weight
                es = self.get_edges()
                for u, v, w in es:
                        e = D.add_edge(ids[u], ids[v])
                        eprop_weight[e] = w

                return D
                        
        def delete(self):
                if self.op == 'wr':
                        return

                cursor = self.db.cursor()
                cursor.execute('DELETE FROM arc WHERE arc.graph_id=?', (self.ident,))
                cursor.execute('DELETE FROM vertex WHERE vertex.graph_id=?', (self.ident,))
                cursor.execute('DELETE FROM graph WHERE graph.id=?', (self.ident,))
                self.db.commit()
                print 'Graph \'' + self.name + '\' deleted from ' + self.dbname 
                
        def finalize(self):
                self.db.close()

def usage(pname):
        print 'usage:', pname, '[[-A?|-E?] | -V? | --delete-graph <graph-name>]', 'dbname.db'
        print '''where
        \t-G?  list the graphs and a summary from the database;
        
        \t--delete-graph <graph-name>  delete the graph named <graph-name> from database;
        
        \t dbname.db - name of the file containing sqlite3 database.'''
        exit(-1)

# density = 2M/(N(N-1))
# M: no. arcs
# N: no. vertices
if __name__=='__main__':
        if len(sys.argv) == 3:
                dbname = sys.argv[2]
                if sys.argv[1] == '-G?':
                        db = sqlite3.connect(dbname)
                        cursor = db.cursor()
                        cursor.execute('SELECT name, has_static_function FROM graph ORDER BY name')
                        rows = cursor.fetchall()
                        print 'Graphs:'
                        print 'Name\t\t\tHas static function?\t\t#vertices\t\t#arcs\t\t\tdensity\t\t\tis bipartite?'
                        for row in rows:
                                G = Graph('rd', dbname, row[0], row[1])
                                DNx = G.to_networkx_graph()
                                print G.name, '\t\t', Graph.func[row[1]], '\t\t\t', G.no_vertices(), '\t\t\t', G.no_arcs(), \
                                        '\t\t\t', nx.density(DNx), '\t\t\t', nx.is_bipartite(DNx)
                        db.close()
                else:
                        usage(sys.argv[0])
        elif len(sys.argv) == 4:
                graph_name = sys.argv[2]
                dbname = sys.argv[3]
                if sys.argv[1] == '--delete-graph':
                        G0 = Graph('rd', dbname, graph_name, 0, True)
                        G0.delete()
        else:
                usage(sys.argv[0])
                
                                
