package io

import (
	"bufio"
	"fmt"
	"io"
	"log"
	"os"
	"strconv"
	"strings"

	g "github.com/aholanda/graphs"
)

// Description of Pajek format
// http://vlado.fmf.uni-lj.si/pub/networks/pajek/doc/draweps.htm

const (
	// Mark the start of a section, after the symbol
	// the section name is written.
	PjkSectionMark byte = '*'
	// Sections in the file
	PjkNetworkSectionEnum  int = 0
	PjkVerticesSectionEnum int = 1
	PjkArcsSectionEnum     int = 2
	// Separate vertices and their names and
	// arcs.
	PjkSeparator string = " "
	// PajekFormatExtension is used as suffix for
	// files with graph description in the Pajek
	// format.
	PajekFormatExtension string = ".net"
)

var PjkSectionNames = [...]string{"network", "vertices", "arcs"}

func WritePajek(digraph *g.Digraph, filename string) {
	file, err := os.Create(filename)
	if err != nil {
		log.Fatalf("failed with error: %v", err)
	}

	// Vertex section
	fmt.Fprintf(file, "%s%s %d\n",
		string(PjkSectionMark),
		PjkSectionNames[PjkVerticesSectionEnum],
		digraph.V())

	vIter := g.NewVertexIterator(digraph)
	for vIter.HasNext() {
		v := vIter.Value()

		fmt.Fprintf(file, "%d%s\"%s\"\n", v+1, PjkSeparator,
			digraph.VertexName(v))
	}

	// arcs section
	fmt.Fprintf(file, "%sarcs\n", string(PjkSectionMark))
	vIter = g.NewVertexIterator(digraph)
	for i := 0; vIter.HasNext(); i++ {
		v := vIter.Value()

		aIter := g.NewArcIterator(digraph, v)
		for aIter.HasNext() {
			w := aIter.Value()
			fmt.Fprintf(file, "%d%v%d\n", v+1, PjkSeparator, w+1)
		}
	}
}

func ReadPajek(filename string) *g.Digraph {
	var line string
	var lineno int          // Line number
	var curSection int = -1 // Mark current section
	var d *g.Digraph
	var graphId string

	file, err := os.Open(filename)
	if err != nil {
		log.Fatalf("failed with error: %v", err)
	}
	defer file.Close()

	// Start reading from the file with a reader.
	reader := bufio.NewReader(file)
	for {
		lineno++
		line, err = reader.ReadString('\n')
		if err == io.EOF {
			break
		}
		// Remove new line
		line = strings.TrimSuffix(line, "\n")

		if line[0] == PjkSectionMark {
			tks := strings.Split(line[1:], PjkSeparator)
			if strings.ToLower(tks[0]) == PjkSectionNames[PjkNetworkSectionEnum] {
				curSection = PjkNetworkSectionEnum
				graphId = tks[1]
				continue
			} else if strings.ToLower(tks[0]) == PjkSectionNames[PjkVerticesSectionEnum] {
				curSection = PjkVerticesSectionEnum
				n, err := strconv.Atoi(tks[1])
				if err != nil {
					log.Fatalf("failed to get the number of vertices at line %d: %v",
						lineno, err)
				}
				d = g.NewDigraph(n)
				d.NameIt(graphId)
				continue
			} else if strings.ToLower(tks[0]) == PjkSectionNames[PjkArcsSectionEnum] {
				curSection = PjkArcsSectionEnum
				continue
			} else {
				log.Fatalf("unknown section name at line %d: \"%s\"", lineno, tks[0])
			}
		}

		// Process line with a vertex
		if curSection == PjkVerticesSectionEnum {
			tks := strings.Split(line, PjkSeparator)
			v, err := strconv.Atoi(tks[0])
			if err != nil {
				log.Fatalf("failed to read the vertex index at line %d: %v ",
					lineno, err)
			}

			if tks[1] != "" {
				// Remove double quotes
				vname := strings.TrimPrefix(tks[1], "\"")
				vname = strings.TrimSuffix(vname, "\"")
				// Name the vertex
				d.NameVertex(g.VertexId(v-1), vname)
			} else {
				log.Fatalf("failed to read the vertex name at line %d ",
					lineno)
			}
		}

		// Process line with an arc
		if curSection == PjkArcsSectionEnum {
			tks := strings.Split(line, PjkSeparator)
			v, err := strconv.Atoi(tks[0])
			if err != nil {
				log.Fatalf("failed to read the vertex source index at line %d: %v ",
					lineno, err)
			}

			w, err := strconv.Atoi(tks[1])
			if err != nil {
				log.Fatalf("failed to read the vertex destination index at line %d: %v ",
					lineno, err)
			}
			d.AddArc(g.VertexId(v-1), g.VertexId(w-1))
		}

		if err != nil {
			break
		}
	}
	return d
}
