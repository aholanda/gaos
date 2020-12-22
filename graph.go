// Copyright 2020 University of São Paulo/Brazil.
// All rights reserved.
// Use of this source code is governed by a MIT-style
// license that can be found in the LICENSE file.

// Package graphs provides a directed graph data structure (Digraph)
// and some operations on it, as well a undirected graph (Graph)
// that is a specialization of Digraph. Using the composition
// to define Graph, some methods of Digraph may be reused.
// See the specification
// [Graphs.tla](https://github.com/aholanda/graphs/blob/master/Graphs.tla)
// using Temporal Logic of Actions (TLA+).
package graphs

import (
	"errors"
	"math"
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

// Digraph represents a directed graph identified
// by ID with N vertices and M arcs where each
// VertexID v is the index of Adjs and each Adjs[v]
// has a collection of neighbors represented by their
// VertexID.
// Its possible to name each VertexID, but it's
// optional.
type Digraph struct {
	// Identification of the graph
	ID string
	// Array of adjacencies where each index is a VertexID v
	// stored sequentially representing where the arc comes from
	// and in the array of the index v is accumulated
	// the VertexID w to where the arc goes to.
	Adjs [][]VertexID
	N    int // Number of vertices
	M    int // Number of arcs
	// Keys array links the VertexID to its name.
	Keys []string
	// Map a VertexID to its name.
	NameToVertex map[string]VertexID
}

// NewDigraph returns a pointer to a newly create
// Digraph structure initialized with the nvertices
// passed as argument to allocate Adjs[] array and
// to set N.
// The structure to name vertices are also initialized.
// A default name is assigned to ID.
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

// NameIt set a name represented by the argument
// id to the digraph. The field is called ID to
// differentiate from vertex name.
func (d *Digraph) NameIt(id string) {
	d.ID = id
}

// String() is the implementation of the
// Stringer interface. When the digraph
// d is printed, this method is used.
func (d *Digraph) String() string {
	return d.ID
}

// VertexIndex returns the VertexID associated with
// the name passed as argument. An non-nil error is
// returned if the name does not exists in the map
// responsible to link vertex's name and its VertexID.
func (d *Digraph) VertexIndex(name string) (VertexID, error) {
	if v, ok := d.NameToVertex[name]; ok {
		return v, nil
	}
	return -1, errors.New("vertex named " + name + " not found")
}

// NameVertex assigned a name to VertexID v if it exists
// in the digraph.
func (d *Digraph) NameVertex(v VertexID, name string) {
	if d.HasVertex(v) {
		if _, ok := d.NameToVertex[name]; !ok {
			d.NameToVertex[name] = v
			d.Keys[v] = name
		}
	}
}

// VertexName returns the name assigned to VertexID v,
// if it exists in the digraph.
func (d *Digraph) VertexName(v VertexID) string {
	if d.HasVertex(v) {
		return d.Keys[v]
	}
	return "v" + strconv.Itoa(int(v))
}

// VertexDegree returns the number of neighbors
// (degree) accumulated in the array d.Adjs[v],
// if v exists in the digraph.
func (d *Digraph) VertexDegree(v VertexID) (int, error) {
	if d.HasVertex(v) {
		return len(d.Adjs[int(v)]), nil
	}
	return -1, errors.New("vertex named " + strconv.Itoa(int(v)) +
		" not found")
}

// V returns the number of vertices in the
// graph also called order of the graph.
func (d *Digraph) V() int {
	return d.N
}

// A returns the number of arcs in the digraph
// also called size of the graph.
func (d *Digraph) A() int {
	return d.M
}

// Size returns the number of arcs in the digraph.
// It does the same function as A, it was included
// to conform with the graph theory's literature.
func (d *Digraph) Size() int {
	return d.M
}

// AddArc creates an arc going from v to w.
// To create an arc VerteXID w in appended
// in the array d.Adjs[v].
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

// AverageDegree calculates the vertices'
// average degree of the digraph. It's used
// the method of provisional means (one-pass algorithm)
// and it is returned the average and the standard deviation
// of the vertices' degrees.
// The algorithm was based on formula expressed in the
// "The Art of Computer Programming", Vol. 2, 3rd edition,
// by Don Knuth, page 232.
func (d *Digraph) AverageDegree() (avg, stdDev float64) {
	const KOld int = 0 // Represents k-1 index
	const KNew int = 1 // Represents k index
	// Average of the first k-1 and k numbers.
	var avgs = [2]float64{0.0, 0.0}
	// Stardard deviation of k-1 and k numbers.
	var stdDevs = [2]float64{0.0, 0.0}
	var deg int = 0 // Vertex degree
	var k int = 0   // data index that starts at 1 and not zero.

	deg, _ = d.VertexDegree(0)
	avgs[KOld] = float64(deg)
	stdDevs[KOld] = 0.0
	for i := 1; i < d.N; i++ {
		k = i + 1
		deg, _ = d.VertexDegree(VertexID(i))
		// average
		avgs[KNew] = avgs[KOld] + (float64(deg)-avgs[KOld])/float64(k)
		// standard deviation
		stdDevs[KNew] = stdDevs[KOld] +
			(float64(deg)-avgs[KOld])*(float64(deg)-avgs[KNew])
		// Update data indexed by k
		avgs[KOld] = avgs[KNew]
		stdDevs[KOld] = stdDevs[KNew]
	}
	return avgs[KNew], math.Sqrt(stdDevs[KNew] / float64(k-1))
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

// Graph is an undirected graph composed by Digraph
// and a counter for the edges called MM.
type Graph struct {
	*Digraph
	MM int
}

// NewGraph creates an undirected Graph and
// returns a pointer to it. The undirected
// Graof is a Digraph with arcs pointed in
// both directions for each vertices' neighbors.
func NewGraph(nvertices int) *Graph {
	d := &Graph{NewDigraph(nvertices), 0}
	d.ID = "graph"
	return d
}

// AddEdge add 2 arcs pointing to v->w and
// w->v, forming the edge v-w. To differentiate
// from Digraph the field g.MM is the counter for
// edges.
func (g *Graph) AddEdge(v, w VertexID) {
	g.AddArc(v, w)
	if v != w {
		g.AddArc(w, v)
	}
	g.MM++
}

// E returns the number of edges in the undirected graph.
func (g *Graph) E() int {
	return g.MM
}

// Size returns the number of edges in the undirected graph.
// It was implement to conform with graph theory literature.
func (g *Graph) Size() int {
	return g.MM
}
