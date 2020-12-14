package graphs

// Algorithm 4.6 from "Algorithms" book
// by Sedgewick and Wayne

type KosarajuSharirSCC struct {
	visited map[*Vertex]bool
	id      map[*Vertex]int
	count   int
	digraph *Digraph
}

func NewKosarajuSharirSCC(d *Digraph) *KosarajuSharirSCC {
	scc := &KosarajuSharirSCC{
		digraph: d,
		visited: make(map[*Vertex]bool, d.Order()),
		id:      make(map[*Vertex]int, d.Order()),
		count:   0,
	}
	vIter := NewVertexIterator(d)
	for vIter.HasNext() {
		v := vIter.Value()
		scc.visited[v] = false
	}
	return scc
}

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
}

func (ks *KosarajuSharirSCC) dfs(v *Vertex) {
	var a *Arc
	var w *Vertex

	ks.visited[v] = true
	ks.id[v] = ks.count

	aIter := NewArcIterator(v)
	for aIter.HasNext() {
		a = aIter.Value()
		w = a.Tip

		if ks.visited[w] == false {
			ks.dfs(w)
		}
	}
}
