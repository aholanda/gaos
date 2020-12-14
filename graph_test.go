package graphs

import (
	"testing"
)

var names = [...]string{"look", "feel", "foo"}

func TestDigraph(t *testing.T) {
	digraph := NewDigraph(3)
	digraph.AddArc(names[0], names[1], 1)
	digraph.AddArc(names[0], names[2], 1)

	if digraph.N != 3 {
		t.Errorf("Number of vertices was incorrect, got: %d, want: %d.", digraph.N, 3)
	}

	if digraph.M != 2 {
		t.Errorf("Number of arcs was incorrect, got: %d, want: %d.", digraph.M, 2)
	}

	vIter := NewVertexIterator(digraph)
	for i := 0; vIter.HasNext(); i++ {
		v := vIter.Value()
		if v.Name != names[i] {
			t.Errorf("Vertex[%d] name was incorrect, got: %v, want: %v.",
				i, names[i], v.Name)
		}

		for a := v.Arcs; a != nil; a = a.Next {
			if a.Tip == nil {
				t.Errorf("Tip is nil for vertex %v", v.Name)
			}
		}
	}
}
