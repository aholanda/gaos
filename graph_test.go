package graphs

import (
	"testing"
)

func TestDigraph(t *testing.T) {
	digraph := NewDigraph(3)
	digraph.AddArc(0, 1)
	digraph.AddArc(0, 2)
	digraph.AddArc(1, 2)
	digraph.AddArc(1, 1)
	digraph.AddArc(2, 0)

	if digraph.V() != 3 {
		t.Errorf("Number of vertices was incorrect, got: %d, want: %d.", digraph.V(), 3)
	}

	if digraph.A() != 5 {
		t.Errorf("Number of arcs was incorrect, got: %d, want: %d.", digraph.A(), 5)
	}
}
