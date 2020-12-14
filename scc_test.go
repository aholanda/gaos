package graphs

import (
	"testing"
)

// Digraph borrowed from "Algorithms" book by Sedgewick/Wayne
// 4th edition chapter 4.2.
func makeDigraph() *Digraph {
	var d *Digraph

	d = NewDigraph(13)
	d.AddArc("0", "1", 1)
	d.AddArc("0", "5", 1)
	d.AddArc("2", "0", 1)
	d.AddArc("2", "3", 1)
	d.AddArc("3", "2", 1)
	d.AddArc("3", "5", 1)
	d.AddArc("4", "2", 1)
	d.AddArc("4", "3", 1)
	d.AddArc("5", "4", 1)
	d.AddArc("6", "0", 1)
	d.AddArc("6", "4", 1)
	d.AddArc("6", "8", 1)
	d.AddArc("6", "9", 1)
	d.AddArc("7", "6", 1)
	d.AddArc("7", "9", 1)
	d.AddArc("8", "6", 1)
	d.AddArc("9", "10", 1)
	d.AddArc("9", "11", 1)
	d.AddArc("10", "12", 1)
	d.AddArc("11", "4", 1)
	d.AddArc("11", "12", 1)
	d.AddArc("12", "9", 1)

	return d
}

func TestKosarajuSharirSCC(t *testing.T) {
	var d *Digraph
	var scc *KosarajuSharirSCC

	d = makeDigraph()
	scc = NewKosarajuSharirSCC(d)
	scc.Compute()

	if scc.count != 5 {
		t.Errorf("Expected %d strongly connected components, got %d", 5, scc.count)
	}
}
