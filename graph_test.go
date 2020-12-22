package graphs

import (
	"testing"
)

func TestDigraph(t *testing.T) {
	degrees := [3]int{3, 2, 1}
	digraph := NewDigraph(3)
	digraph.AddArc(0, 1)
	digraph.AddArc(0, 2)
	digraph.AddArc(0, 0)
	digraph.AddArc(1, 0)
	digraph.AddArc(1, 2)
	digraph.AddArc(2, 1)

	if digraph.V() != 3 {
		t.Errorf("Number of vertices was incorrect, got: %d, want: %d.", digraph.V(), 3)
	}

	if digraph.A() != 6 {
		t.Errorf("Number of arcs was incorrect, got: %d, want: %d.", digraph.A(), 6)
	}

	for i, d := range degrees {
		deg, _ := digraph.VertexDegree(VertexID(i))
		if d != deg {
			t.Errorf("Degree for vertex %d was incorrect, got: %d, want: %d.",
				i, deg, d)
		}
	}

	deg, _ := digraph.VertexDegree(VertexID(0))
	if deg != 3 {
		t.Errorf("Degree of vertex %d was incorrect, got: %d, want: %d.", 0, deg, 3)
	}

	avg, _ := digraph.AverageDegree()
	if avg != 2.0 {
		t.Errorf("Average degree of digraph was incorrect, got: %v, want: %v.", avg, 2.0)
	}

	_, stdDev := digraph.AverageDegree()
	if stdDev != 1.0 {
		t.Errorf("Standard deviation of average degree of digraph was incorrect, got: %f, want: %f.",
			stdDev, 1.0)
	}

}
