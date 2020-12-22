package graphs

import (
	"testing"
)

// Digraph borrowed from "Algorithms" book by Sedgewick/Wayne
// 4th edition chapter 4.2.
func makeDigraph() *Digraph {
	var d *Digraph

	d = NewDigraph(13)
	d.AddArc(0, 1)
	d.AddArc(0, 5)
	d.AddArc(2, 0)
	d.AddArc(2, 3)
	d.AddArc(3, 2)
	d.AddArc(3, 5)
	d.AddArc(4, 2)
	d.AddArc(4, 3)
	d.AddArc(5, 4)
	d.AddArc(6, 0)
	d.AddArc(6, 4)
	d.AddArc(6, 8)
	d.AddArc(6, 9)
	d.AddArc(7, 6)
	d.AddArc(7, 9)
	d.AddArc(8, 6)
	d.AddArc(9, 10)
	d.AddArc(9, 11)
	d.AddArc(10, 12)
	d.AddArc(11, 4)
	d.AddArc(11, 12)
	d.AddArc(12, 9)

	return d
}

func TestKosarajuSharirSCC(t *testing.T) {
	var d *Digraph
	var scc *KosarajuSharirSCC
	// Expected number of vertices for each strongly
	// connected component.
	var expSCCElems [5]int = [5]int{1, 5, 4, 2, 1}

	d = makeDigraph()
	scc = NewKosarajuSharirSCC(d)
	scc.Compute()

	sccToV := make(map[int][]int)
	for v := range scc.id {
		c := scc.id[v]
		if _, ok := sccToV[c]; !ok {
			sccToV[c] = make([]int, 0)
		}
		sccToV[c] = append(sccToV[c], v)
	}
	for c := 0; c < scc.count; c++ {
		if len(sccToV[c]) != expSCCElems[c] {
			t.Errorf("Expected %d vertices for SCC #%d, got %d", expSCCElems[c], c+1, len(sccToV[c]))
		}
	}

	count := scc.Count()
	if count != 5 {
		t.Errorf("Expected %d strongly connected components, got %d", 5, count)
	}

	gcs := scc.GreatestComponentSize()
	if gcs != 5 {
		t.Errorf("Expected %d vertices in the greatest strongly connected components, got %d",
			5, gcs)
	}
}
