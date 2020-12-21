// Copyright 2020 University of São Paulo/Brazil.
// All rights reserved.
// Use of this source code is governed by a MIT-style
// license that can be found in the LICENSE file.

package graphs

import (
	"errors"
	"strconv"
)

// VertexID is aliased to int because it is
// used as index in the array of adjacencies.
// A vertex is simply an index in the array.
// Each element of the array is another array of
// neighbors of the vertex index.
// Their neighbors are also indices in the
// array of adjacencies.
type VertexID int

type Digraph struct {
	ID           string              // name of the graph
	Adjs         [][]VertexID        // array of adjacencies
	N            int                 // number of vertices
	M            int                 // number of arcs
	Keys         []string            // store vertices' names
	NameToVertex map[string]VertexID // names for vertices (optional)
}

func NewDigraph(nvertices int) *Digraph {
	d := &Digraph{
		ID:           "digraph",
		Adjs:         make([][]VertexID, nvertices),
		N:            nvertices,
		M:            0, // number of arcs
		Keys:         make([]string, nvertices),
		NameToVertex: make(map[string]VertexID, nvertices),
	}
	for i := range d.Adjs {
		d.Adjs[i] = make([]VertexID, 0)
	}
	return d
}

func (d *Digraph) NameIt(id string) {
	d.ID = id
}

func (d *Digraph) Name() string {
	return d.ID
}

func (d *Digraph) VertexIndex(name string) (VertexID, error) {
	if v, ok := d.NameToVertex[name]; ok {
		return v, nil
	}
	return -1, errors.New("vertex named " + name + " not found")
}

func (d *Digraph) NameVertex(v VertexID, name string) {
	if d.HasVertex(v) {
		if _, ok := d.NameToVertex[name]; !ok {
			d.NameToVertex[name] = v
			d.Keys[v] = name
		}
	}
}

func (d *Digraph) VertexName(v VertexID) string {
	if d.HasVertex(v) {
		return d.Keys[v]
	}
	return "v" + strconv.Itoa(int(v))
}

// Order of the graph
func (d *Digraph) V() int {
	return d.N
}

// Size of the graph in arcs
func (d *Digraph) A() int {
	return d.M
}

// Size of the graph in arcs
func (d *Digraph) Size() int {
	return d.M
}

func (d *Digraph) AddArc(v, w VertexID) error {
	if d.HasVertex(v) == false {
		from := strconv.Itoa(int(v))
		return errors.New("vertex index " + from + " is out of bounds")
	}

	if d.HasVertex(w) == false {
		to := strconv.Itoa(int(w))
		return errors.New("vertex index " + to + " is out of bounds")
	}

	d.Adjs[v] = append(d.Adjs[v], w)

	d.M++

	return nil
}

// HasVertex checks if the VertexID v is in the
// bounds of array of vertices' indices.
func (d *Digraph) HasVertex(v VertexID) bool {
	if int(v) >= 0 && int(v) < d.N {
		return true
	}
	return false
}

// Reverse generates a new digraph reverting
// the direction of all arcs in the Digraph d,
// the function converts v -> w to w -> v traversing
// all vertices in the original digraph.
func Reverse(d *Digraph) *Digraph {
	rev := NewDigraph(d.N)
	rev.ID = d.ID + "Reversed"
	for v := range d.Adjs {
		for _, w := range d.Adjs[v] {
			rev.AddArc(w, VertexID(v))
		}
	}
	return rev
}

type Graph struct {
	*Digraph
	MM int
}

func NewGraph(nvertices int) *Graph {
	d := &Graph{NewDigraph(nvertices), 0}
	d.ID = "graph"
	return d
}

func (g *Graph) AddEdge(v, w VertexID) {
	g.AddArc(v, w)
	if v != w {
		g.AddArc(w, v)
	}
	g.MM++
}

// Size of the graph in edges
func (g *Graph) E() int {
	return g.MM
}

func (g *Graph) Size() int {
	return g.MM
}
