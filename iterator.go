// Copyright 2020 University of São Paulo/Brazil.
// All rights reserved.
// Use of this source code is governed by a MIT-style
// license that can be found in the LICENSE file.

package graphs

// VertexIterator acts as a proxy to use
// simpler methods to iterate the vertices
// in the digraph.
type VertexIterator struct {
	curIdx  int
	digraph *Digraph
}

// NewVertexIterator creates a VertexIterator and return
// a pointer to the newly created structure.
func NewVertexIterator(d *Digraph) *VertexIterator {
	return &VertexIterator{
		curIdx:  0,
		digraph: d,
	}
}

// HasNext returns true if there is more
// vertices to explore and false otherwise.
func (vi *VertexIterator) HasNext() bool {
	return vi.curIdx < vi.digraph.V()
}

// Value returns the next VertexID not
// explored yet. It is recommended to use
// in conjunction with HasNext to not pass
// the bounds of vertices ids.
func (vi *VertexIterator) Value() VertexID {
	var v VertexID
	v = VertexID(vi.curIdx)
	vi.curIdx++

	return v
}

// ArcIterator acts as a proxy to traverse
// the neighbors of a current VertexID
// represented by curIdx in the digraph.
type ArcIterator struct {
	digraph *Digraph
	curIdx  int
	curAdj  []VertexID
}

// NewArcIterator creates a ArcIterator and return
// a pointer to newly created structure.
func NewArcIterator(d *Digraph, v VertexID) *ArcIterator {
	return &ArcIterator{
		digraph: d,
		curIdx:  0,
		curAdj:  d.Adjs[v],
	}
}

// HasNext returns true if there is more
// neighbors to explore and false otherwise.
func (vi *ArcIterator) HasNext() bool {
	return vi.curIdx < len(vi.curAdj)
}

// Value returns the next VertexID neighbor
// not explored yet. It is recommended to use
// in conjunction with HasNext to not pass
// the bounds of vertices ids of the neighbors.
func (vi *ArcIterator) Value() VertexID {
	var w VertexID
	w = vi.curAdj[vi.curIdx]
	vi.curIdx++

	return w
}
