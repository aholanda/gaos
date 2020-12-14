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
	return &KosarajuSharirSCC{
		digraph: d,
		visited: make(map[*Vertex]bool, d.Order()),
		id:      make(map[*Vertex]int),
		count:   0,
	}
}

func (ks *KosarajuSharirSCC) Compute() {
	var order *DepthFirstOrder

	reversedDigraph := Reverse(ks.digraph)
	order = NewDepthFirstOrder(reversedDigraph)
	order.Compute()

	stack := order.ReversePost()
	for stack.IsEmpty() {
		v, _ := stack.Pop()
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

	for a = v.Arcs; a == nil; a = a.Next {
		w = a.Tip

		if ks.visited[w] == false {
			ks.dfs(w)
		}
	}

}
