// Copyright 2020 University of São Paulo/Brazil.
// All rights reserved.
// Use of this source code is governed by a MIT-style
// license that can be found in the LICENSE file.

package graphs

// DepthFirstOrder structure contains the data types
// to store the one pass depth-first search (DFS) visits
// in the vertices of a digraph, storing the preorder,
// postorder and reverse postorder visits in the vertices,
// having as pivot the DFS recursive calls.
type DepthFirstOrder struct {
	// Mark if the Compute (DFS) method was performed.
	wasComputed bool
	// The digraph to apply the Depth-First Search (DFS).
	digraph *Digraph
	// Mark the visited vertices using their indices.
	visited []bool
	// Preorder: queue to put the vertices before recursive
	// DFS calls.
	pre []VertexID
	// Postorder: queue to put the vertices after recursive
	// DFS calls.
	post []VertexID
	// Reverse postorder: stack to put the vertices after the recursive
	// DFS calls in reverse order of visiting.
	reversePost *stackV
}

// NewDepthFirstOrder creates and initializes a
// DepthFirstOrder struture to perform the DFS
// computation.
func NewDepthFirstOrder(d *Digraph) *DepthFirstOrder {
	dfo := DepthFirstOrder{
		digraph:     d,
		visited:     make([]bool, d.V()),
		pre:         make([]VertexID, d.V()),
		post:        make([]VertexID, d.V()),
		reversePost: newStackV(d.V()),
	}
	vIter := NewVertexIterator(d)
	for vIter.HasNext() {
		v := vIter.Value()
		dfo.visited[v] = false
	}
	return &dfo
}

// Compute performs the dfs method in the
// vertices of the digraph.
func (dfo *DepthFirstOrder) Compute() {
	vIter := NewVertexIterator(dfo.digraph)
	for vIter.HasNext() {
		v := vIter.Value()
		if dfo.visited[v] == false {
			dfo.dfs(dfo.digraph, v)
		}
	}
	dfo.wasComputed = true
}

// dfs calls itself recursivelly visiting the vertices
// in preorder, postorder and reverse postorder. The visits
// are accumulated in first order (one pass) in the pre,
// post and reversePost fields from DepthFirstOrder structure.
func (dfo *DepthFirstOrder) dfs(d *Digraph, v VertexID) {
	dfo.pre = append(dfo.pre, v)

	dfo.visited[v] = true
	aIter := NewArcIterator(d, v)
	for aIter.HasNext() {
		w := aIter.Value()
		if dfo.visited[w] == false {
			dfo.dfs(d, w)
		}
	}
	dfo.post = append(dfo.post, v)
	dfo.reversePost.push(v)
}

// hadRunCompute is the implementation of the
// method with same name in the interface ComputingPerformer
// to indicate if the Compute method was already called.
func (dfo *DepthFirstOrder) hadRunCompute() bool {
	return dfo.wasComputed
}

// Pre returns an queue (array) with the vertices
// visited in preorder by DFS algorithm.
func (dfo *DepthFirstOrder) Pre() []VertexID {
	ComputeWasCalled(dfo)

	return dfo.pre
}

// Post returns an queue (array) with the vertices
// visited in postorder by DFS algorithm.
func (dfo *DepthFirstOrder) Post() []VertexID {
	ComputeWasCalled(dfo)

	return dfo.post
}

// ReversePost returns an queue (array) with the vertices
// visited in reverse postorder by DFS algorithm.
func (dfo *DepthFirstOrder) ReversePost() []VertexID {
	ComputeWasCalled(dfo)

	return dfo.reversePost.verts
}
