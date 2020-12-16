package io

import (
	"testing"

	g "github.com/aholanda/graphs"
)

const V int = 3 // number of vertices
const A int = 5 // number of arcs
var filename = "/tmp/foo.net"
var vNames = [...]string{"look", "feel", "great"}

func TestWritePajek(t *testing.T) {
	d := g.NewDigraph(V)
	for i := 0; i < V; i++ {
		d.NameVertex(g.VertexId(i), vNames[i])
	}
	d.AddArc(0, 1)
	d.AddArc(0, 2)
	d.AddArc(1, 0)
	d.AddArc(1, 1)
	d.AddArc(2, 1)

	if d.V() != V {
		t.Errorf("number of vertices was incorrect, got: %d, want: %d.", d.V(), V)
	}

	if d.A() != A {
		t.Errorf("number of arcs was incorrect, got: %d, want: %d.", d.A(), A)
	}
	WritePajek(d, filename)
}

func TestReadPajek(t *testing.T) {
	var d *g.Digraph

	d = ReadPajek(filename)

	for i := 0; i < d.V(); i++ {
		if d.VertexName(g.VertexId(i)) != vNames[i] {
			t.Errorf("name for vertex %d was incorrect, got: %v, want: %s.",
				i, d.VertexName(g.VertexId(i)), vNames[i])
		}
	}

	if d.V() != V {
		t.Errorf("number of vertices was incorrect, got: %d, want: %d.", d.V(), V)
	}

	if d.A() != A {
		t.Errorf("number of arcs was incorrect, got: %d, want: %d.", d.A(), A)
	}
}
