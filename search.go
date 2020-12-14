package graphs

type DepthFirstOrder struct {
	digraph     *Digraph
	visited     map[*Vertex]bool
	pre         []*Vertex // vertices in preorder
	post        []*Vertex // vertices in postorder
	reversePost *stackV   // vertices in reverse
}

func NewDepthFirstOrder(d *Digraph) *DepthFirstOrder {
	dfo := DepthFirstOrder{
		digraph:     d,
		visited:     make(map[*Vertex]bool),
		pre:         make([]*Vertex, d.Order()),
		post:        make([]*Vertex, d.Order()),
		reversePost: newStackV(d.Order()),
	}
	vIter := NewVertexIterator(d)
	for vIter.HasNext() {
		v := vIter.Value()
		dfo.visited[v] = false
	}
	return &dfo
}

func (dfo *DepthFirstOrder) Compute() {
	vIter := NewVertexIterator(dfo.digraph)
	for vIter.HasNext() {
		v := vIter.Value()
		if dfo.visited[v] == false {
			dfo.dfs(dfo.digraph, v)
		}
	}
}

func (dfo *DepthFirstOrder) dfs(d *Digraph, v *Vertex) {
	dfo.pre = append(dfo.pre, v)

	dfo.visited[v] = true
	aIter := NewArcIterator(v)
	for aIter.HasNext() {
		a := aIter.Value()
		w := a.Tip
		if dfo.visited[w] == false {
			dfo.dfs(d, w)
		}
	}
	dfo.post = append(dfo.post, v)
	dfo.reversePost.push(v)
}

func (dfo *DepthFirstOrder) Pre() []*Vertex {
	return dfo.pre
}

func (dfo *DepthFirstOrder) Post() []*Vertex {
	return dfo.post
}

func (dfo *DepthFirstOrder) ReversePost() []*Vertex {
	return dfo.reversePost.verts
}
