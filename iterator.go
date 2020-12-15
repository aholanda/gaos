package graphs

// Vertices
type VertexIterator struct {
	curIdx int
	graph  *Digraph
}

func NewVertexIterator(d *Digraph) *VertexIterator {
	return &VertexIterator{
		curIdx: 0,
		graph:  d,
	}
}

func (vi *VertexIterator) Value() VertexId {
	var v VertexId
	v = VertexId(vi.curIdx)
	vi.curIdx++

	return v
}

func (vi *VertexIterator) HasNext() bool {
	return vi.curIdx < vi.graph.V()
}

// Arcs
type ArcIterator struct {
	digraph *Digraph
	curIdx  int
	curAdj  []VertexId
}

func NewArcIterator(d *Digraph, v VertexId) *ArcIterator {
	return &ArcIterator{
		digraph: d,
		curIdx:  0,
		curAdj:  d.Adjs[v],
	}
}

func (vi *ArcIterator) Value() VertexId {
	var w VertexId
	w = vi.curAdj[vi.curIdx]
	vi.curIdx++

	return w
}

func (vi *ArcIterator) HasNext() bool {
	return vi.curIdx < len(vi.curAdj)
}
