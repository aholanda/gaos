package io

import (
	"testing"

	g "github.com/aholanda/graphs"
)

func TestWritePjk(t *testing.T) {
	graph := g.NewDigraph(3)
	graph.AddArc("look", "feel", 1)

	if graph.N != 2 {
		t.Errorf("Sum was incorrect, got: %d, want: %d.", graph.N, 2)
	}
	WritePjk(graph, "/tmp/foo.net")
}
