package graphs

type DepthFirstOrder struct {
	digraph     *Digraph
	visited     []bool
	pre         []VertexID // vertices in preorder
	post        []VertexID // vertices in postorder
	reversePost *stackV    // vertices in reverse
}

func NewDepthFirstOrder(d *Digraph) *DepthFirstOrder {
	dfo := DepthFirstOrder{
		digraph:     d,
		visited:     make([]bool, d.V()),
		pre:         make([]VertexID, d.V()),
		post:        make([]VertexID, d.V()),
		reversePost: newStackV(d.V()),
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

func (dfo *DepthFirstOrder) dfs(d *Digraph, v VertexID) {
	dfo.pre = append(dfo.pre, v)

	dfo.visited[v] = true
	aIter := NewArcIterator(d, v)
	for aIter.HasNext() {
		w := aIter.Value()
		if dfo.visited[w] == false {
			dfo.dfs(d, w)
		}
	}
	dfo.post = append(dfo.post, v)
	dfo.reversePost.push(v)
}

func (dfo *DepthFirstOrder) Pre() []VertexID {
	return dfo.pre
}

func (dfo *DepthFirstOrder) Post() []VertexID {
	return dfo.post
}

func (dfo *DepthFirstOrder) ReversePost() []VertexID {
	return dfo.reversePost.verts
}
