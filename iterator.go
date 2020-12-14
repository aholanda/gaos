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

func (vi *VertexIterator) Value() *Vertex {
	var v *Vertex
	v = &vi.graph.Vertices[vi.curIdx]
	vi.curIdx += 1

	return v
}

func (vi *VertexIterator) HasNext() bool {
	return vi.curIdx < len(vi.graph.Vertices)
}

// Arcs
type ArcIterator struct {
	curArc *Arc
}

func NewArcIterator(v *Vertex) *ArcIterator {
	return &ArcIterator{
		curArc: v.Arcs,
	}
}

func (vi *ArcIterator) Value() *Arc {
	var a *Arc
	a = vi.curArc
	vi.curArc = vi.curArc.Next

	return a
}

func (vi *ArcIterator) HasNext() bool {
	return vi.curArc != nil
}
