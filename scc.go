package graphs

// Algorithm 4.6 from "Algorithms" book
// by Sedgewick and Wayne

type KosarajuSharirSCC struct {
	visited []bool
	id      []int
	count   int
	digraph *Digraph
}

func NewKosarajuSharirSCC(d *Digraph) *KosarajuSharirSCC {
	scc := &KosarajuSharirSCC{
		digraph: d,
		visited: make([]bool, d.V()),
		id:      make([]int, d.V()),
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

func (ks *KosarajuSharirSCC) dfs(v VertexId) {
	ks.visited[v] = true
	ks.id[v] = ks.count

	aIter := NewArcIterator(ks.digraph, v)
	for aIter.HasNext() {
		w := aIter.Value()

		if ks.visited[w] == false {
			ks.dfs(w)
		}
	}
}
