package graphs

// Source: https://www.educative.io/edpresso/how-to-implement-a-stack-in-golang
type stackV struct {
	verts []*Vertex
	n     int // number of vertices filled in the array
}

func newStackV(nverts int) *stackV {
	return &stackV{
		verts: make([]*Vertex, nverts),
		n:     0,
	}
}

// IsEmpty: check if stack is empty
func (s *stackV) isEmpty() bool {
	return s.n == 0
}

// IsFull: check if stack is full
func (s *stackV) isFull() bool {
	return s.n == len(s.verts)
}

// Push a new value onto the stack
func (s *stackV) push(v *Vertex) {
	if s.isFull() == false {
		// Simply append the new value to the end of the stack
		s.verts[len(s.verts)-s.n-1] = v
		s.n++
	}
}
