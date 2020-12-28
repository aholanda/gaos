// Copyright 2020 University of São Paulo/Brazil.
// All rights reserved.
// Use of this source code is governed by a MIT-style
// license that can be found in the LICENSE file.

package graphs

import (
	"sort"
)

// KosarajuSharirSCC contains the fields
// needed to find the strongly connected
// components in the digraph using Kosaraju-Sharir
// algorithm that is based on the Algorithm 4.6 from
// "Algorithms" book by Sedgewick and Wayne.
type KosarajuSharirSCC struct {
	// Mark if the Compute method was performed.
	wasComputed bool
	// Mark the visited vertices.
	visited []bool
	// Array where the VertexID is the index and the
	// value is the component number which VertexID
	// pertains.
	id []int
	// Number of strongly
	count int
	// Digraph to find the strongly connected components.
	digraph *Digraph
}

// NewKosarajuSharirSCC only created the structure
// KosarajuSharirSCC and initialize its fields.
// The method Compute() must be called to perform
// the algorithm.
func NewKosarajuSharirSCC(d *Digraph) *KosarajuSharirSCC {
	scc := &KosarajuSharirSCC{
		wasComputed: false,
		digraph:     d,
		visited:     make([]bool, d.V()),
		id:          make([]int, d.V()),
		count:       0,
	}
	vIter := NewVertexIterator(d)
	for vIter.HasNext() {
		v := vIter.Value()
		scc.visited[v] = false
	}
	return scc
}

// Compute performs the Kosaraju-Sharir
// algorithm. Basically, the original digraph
// is post reversed and a depth-first search
// in the reversed graph is performed to find
// the components.
func (ks *KosarajuSharirSCC) Compute() {
	var order *DepthFirstOrder

	order = NewDepthFirstOrder(Reverse(ks.digraph))
	order.Compute()

	for _, v := range order.ReversePost() {
		if ks.visited[v] == false {
			ks.dfs(v)
			ks.count++
		}
	}
	ks.wasComputed = true
}

// dfs performs the Depth-First Search algorithm
// in the digraph of KosarajuSharirSCC starting
// at VertexID v.
func (ks *KosarajuSharirSCC) dfs(v VertexID) {
	ks.visited[v] = true
	ks.id[v] = ks.count

	aIter := NewArcIterator(ks.digraph, v)
	for aIter.HasNext() {
		w := aIter.Value()

		if ks.visited[w] == false {
			ks.dfs(w)
		}
	}
}

// hadRunCompute is the implementation of the
// method with same name in the interface ComputingPerformer
// to indicate if the Compute method was already called.
func (ks *KosarajuSharirSCC) hadRunCompute() bool {
	return ks.wasComputed
}

// Count returns the number of connected
// components found.
func (ks *KosarajuSharirSCC) Count() int {
	ComputeWasCalled(ks)

	return ks.count
}

// LargestComponentSize returns the number of vertices
// in the largest strongly connected component.
func (ks *KosarajuSharirSCC) LargestComponentSize() int {
	// idToSize maps the id of the component and the number
	// of vertices in it.
	var idToSize map[int]int

	ComputeWasCalled(ks)

	idToSize = make(map[int]int)
	for _, id := range ks.id {
		if _, ok := idToSize[id]; !ok {
			idToSize[id] = 1
		} else {
			idToSize[id]++
		}
	}

	p := make(PairList, len(idToSize))
	i := 0
	for k, v := range idToSize {
		p[i] = Pair{k, v}
		i++
	}
	sort.Sort(sort.Reverse(p))

	return p[0].Value
}

// Pair is used to sort a set of pair elements
// by Value.
type Pair struct {
	Key   int
	Value int
}

// PairList is an alias to an array of Pair.
type PairList []Pair

// Len return the length of Pair[] array.
func (p PairList) Len() int { return len(p) }

// Swap interchange positions of two pairs.
func (p PairList) Swap(i, j int) { p[i], p[j] = p[j], p[i] }

// Less compares Values of 2 Pairs
func (p PairList) Less(i, j int) bool { return p[i].Value < p[j].Value }
