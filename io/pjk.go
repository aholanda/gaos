package io

import (
	"fmt"
	"os"

	g "github.com/aholanda/graphs"
)

const (
	// Mark the start of a section, after the symbol
	// the section name is written.
	PjkSectionMark string = "*"
	// Sections in the file
	PjkVerticesSectionEnum int = iota
	PjkArcsSectionEnum
	// Separate vertices and their names and
	// arcs.
	PjkSeparator string = " "
)

var PjkSectionNames = [...]string{"Vertices", "arcs"}

func WritePjk(digraph *g.Digraph, filename string) {
	// Map vertex pointer and its index
	var vertexToIndex map[*g.Vertex]int = make(map[*g.Vertex]int,
		digraph.Order())

	file, err := os.Create(filename)
	check(err, filename, -1)

	// Vertex section
	fmt.Fprintf(file, "%v%v %d\n",
		PjkSectionMark,
		PjkSectionNames[PjkVerticesSectionEnum],
		digraph.Order())

	vIter := g.NewVertexIterator(digraph)
	for i := 0; vIter.HasNext(); i++ {
		v := vIter.Value()
		vertexToIndex[v] = i

		fmt.Fprintf(file, "%d%s\"%s\"", i, PjkSeparator, v.Name)
	}

	// arcs section
	fmt.Fprintf(file, "%varcs\n", PjkSectionMark)
	vIter = g.NewVertexIterator(digraph)
	for i := 0; vIter.HasNext(); i++ {
		v := vIter.Value()
		vi := vertexToIndex[v]

		for a := v.Arcs; a == nil; a = a.Next {
			w := a.Tip
			wi := vertexToIndex[w]
			fmt.Fprintf(file, "%d%v%d%v%d\n", vi, PjkSeparator, wi,
				PjkSeparator, a.Len)

		}
	}
}
