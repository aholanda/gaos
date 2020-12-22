// Copyright 2020 University of São Paulo/Brazil.
// All rights reserved.
// Use of this source code is governed by a MIT-style
// license that can be found in the LICENSE file.

package graphs_test

import (
	"fmt"

	g "github.com/aholanda/graphs"
)

func Example() {
	var digraph *g.Digraph
	// A Digraph with 3 vertices is created
	// and its pointer returned.
	digraph = g.NewDigraph(3)
	// The vertices may have a name/label associated
	// with them.
	digraph.NameVertex(0, "feel")
	digraph.NameVertex(1, "look")
	digraph.NameVertex(2, "smell")
	// Arcs to Digraph are inserted easily
	// using their indices that must obey the bounds
	// 0 <= v < 3.
	digraph.AddArc(0, 1)
	digraph.AddArc(0, 2)
	digraph.AddArc(0, 0)
	digraph.AddArc(1, 0)
	digraph.AddArc(1, 2)
	digraph.AddArc(2, 1)

	// One way to traverse the digraph is incrementing
	// their indices from 0 up to the capacity V().
	for v := 0; v < digraph.V(); v++ {
		fmt.Printf("%d:", v)
		// The neighbors of v are accessed looping
		// the Adjs[v] array.
		for _, w := range digraph.Adjs[v] {
			fmt.Printf(" %d", w)
		}
		fmt.Println()
	}

	// Output
	// 0: 1 2 0
	// 1: 0 2
	// 2: 1

	// Another way to traverse the same digraph
	// is using the iterator structure.
	vIter := g.NewVertexIterator(digraph)
	for vIter.HasNext() { // vertices
		v := vIter.Value()
		fmt.Printf("%d:", v)
		aIter := g.NewArcIterator(digraph, v)
		for aIter.HasNext() { // arcs|edges
			w := aIter.Value()
			fmt.Printf(" %d", w)
		}
		fmt.Println()
	}
	// Output
	// 0: 1 2 0
	// 1: 0 2
	// 2: 1
}
