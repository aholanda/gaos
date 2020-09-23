#!/usr/bin/env python

import graph_tool as gt
import subprocess
import os

import net

graphname = 'linux-4.4.0'

G = gt.load_graph(graphname + '.xml.gz')
#G.save(graphname + '.xml.gz')
#net.draw_graph(graphname)

net.plot_degree_distrib(G, graphname)
