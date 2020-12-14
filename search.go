package graphs

// Source: https://www.educative.io/edpresso/how-to-implement-a-stack-in-golang
type Stack []*Vertex

// IsEmpty: check if stack is empty
func (s *Stack) IsEmpty() bool {
	return len(*s) == 0
}

// Push a new value onto the stack
func (s *Stack) Push(v *Vertex) {
	*s = append(*s, v) // Simply append the new value to the end of the stack
}

// Remove and return top element of stack. Return false if stack is empty.
func (s *Stack) Pop() (*Vertex, bool) {
	if s.IsEmpty() {
		return nil, false
	} else {
		index := len(*s) - 1   // Get the index of the top most element.
		element := (*s)[index] // Index into the slice and obtain the element.
		*s = (*s)[:index]      // Remove it from the stack by slicing it off.
		return element, true
	}
}

type DepthFirstOrder struct {
	digraph     *Digraph
	visited     map[*Vertex]bool
	pre         []*Vertex // vertices in preorder
	post        []*Vertex // vertices in postorder
	reversePost *Stack    // vertices in reverse
}

func NewDepthFirstOrder(d *Digraph) *DepthFirstOrder {
	return &DepthFirstOrder{
		digraph: d,
		visited: make(map[*Vertex]bool),
		pre:     make([]*Vertex, d.Order()),
		post:    make([]*Vertex, d.Order()),
	}
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
	for a := v.Arcs; a == nil; a = a.Next {
		w := a.Tip
		if dfo.visited[w] == false {
			dfo.dfs(d, w)
		}
	}
	dfo.post = append(dfo.post, v)
	dfo.reversePost.Push(v)
}

func (dfo *DepthFirstOrder) Pre() []*Vertex {
	return dfo.pre
}

func (dfo *DepthFirstOrder) Post() []*Vertex {
	return dfo.post
}

func (dfo *DepthFirstOrder) ReversePost() *Stack {
	return dfo.reversePost
}
