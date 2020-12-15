package graphs

type DepthFirstOrder struct {
	digraph     *Digraph
	visited     []bool
	pre         []VertexId // vertices in preorder
	post        []VertexId // vertices in postorder
	reversePost *stackV    // vertices in reverse
}

func NewDepthFirstOrder(d *Digraph) *DepthFirstOrder {
	dfo := DepthFirstOrder{
		digraph:     d,
		visited:     make([]bool, d.V()),
		pre:         make([]VertexId, d.V()),
		post:        make([]VertexId, d.V()),
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

func (dfo *DepthFirstOrder) dfs(d *Digraph, v VertexId) {
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

func (dfo *DepthFirstOrder) Pre() []VertexId {
	return dfo.pre
}

func (dfo *DepthFirstOrder) Post() []VertexId {
	return dfo.post
}

func (dfo *DepthFirstOrder) ReversePost() []VertexId {
	return dfo.reversePost.verts
}
