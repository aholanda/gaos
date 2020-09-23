package main

import ("fmt"
	"math"
	"math/rand"
	"sort"
	"strconv"

	"image"
	"image/color"
	"image/gif"
	"os"
)

const (
	INFTY = math.MaxInt64
	K = 4 // critical index
)

var palette = []color.Color{
	color.RGBA{0xff, 0xff, 0xff, 0xff}, // white
	color.RGBA{0xff, 0xff, 0x00, 0xff}, // yellow
	color.RGBA{0x00, 0xff, 0x00, 0xff}, // green
        color.RGBA{0xff, 0x00, 0x00, 0xff}, // red
	color.RGBA{0x00, 0x00, 0x00, 0xff}, // black
}

type SandPile struct{
	rows, cols int
	data [][]int
	avalancheId int // counter for the avalanches
	avalancheId2size map[int]int // map avalanche identification to size
	maxAvalanches int // maximum number of avalanches
}

func MakeSandPile(rows, cols int) (*SandPile) {
	var sp SandPile

	sp.rows = rows
	sp.cols = cols
	sp.avalancheId2size = make(map[int]int)

	// otherwise, no limits to maximum number of avalanches
	sp.maxAvalanches = INFTY
	
	sp.data = make([][]int, rows)
	for i := 0; i < rows; i++ {
		sp.data[i] = make([]int, cols)
		for j := 0; j < cols; j++ {
			sp.data[i][j] = 0 // initialization
		}
	}
	return &sp
}

func (sp *SandPile) SetCellState(i, j, val int) {
	(*sp).data[i][j] = val
}

func (sp *SandPile) GetCellState(i, j int) int {
	return (*sp).data[i][j]
}

// isRoot is used to know which one is the first avalanche
func (sp *SandPile) EvalCellState(i, j int, isRoot bool) bool {
	state := (*sp).GetCellState(i, j)

	// critical state, avalanche occurs
	if state == K {
		(*sp).SetCellState(i, j, 0)

		if isRoot == true {
			(*sp).avalancheId++
			(*sp).avalancheId2size[(*sp).avalancheId] = 1

			// Bounded by maximum number of avalanches if set
			if (*sp).avalancheId > (*sp).maxAvalanches {
				return false;
			}
		}
		
		(*sp).avalancheId2size[(*sp).avalancheId]++
		
		// redistribute sand to mate cells
		// in golang -1 % 0 = -1
		var x,y int
		if i-1 >= 0 {
			x = (i-1)
			(*sp).data[x][j]++
			(*sp).EvalCellState(x, j, false)		
		}
		if i+1 < (*sp).cols {
			x = (i+1)
			(*sp).data[x][j]++
			(*sp).EvalCellState(x, j, false)
		}
		if j-1 >= 0 {
			y = (j-1)
			(*sp).data[i][y]++
			(*sp).EvalCellState(i, y, false)
		}
		if j+1 < (*sp).rows {
			y = (j+1)
			(*sp).data[i][y]++
			(*sp).EvalCellState(i, y, false)
		}
	}
	return true
}

func main() {
	// Sand pile
	var w, h int = 64, 64
	sp := MakeSandPile(w, h) // sand pile
	sp.maxAvalanches = 128
	// Map size of avalanche to its frequence of occurrence
	size2freq := make(map[int]int)

	// Image
	var images []*image.Paletted
	var delays []int
	
	
	for {
		// choose coordinate to add sand
		// 0 <= n < 40
		x := rand.Intn(w)
		y := rand.Intn(h)

		t :=  sp.GetCellState(x, y)
		
		t++ 

		sp.SetCellState(x, y, t)

		if sp.EvalCellState(x, y, true) == false {
			break
		}

		img := image.NewPaletted(image.Rect(0, 0, w, h), palette)
		images = append(images, img)
		delays = append(delays, 8)
		for x := 0; x < w; x++ {
			for y := 0; y < h; y++ {
				z := sp.GetCellState(x,y)
				img.Set(x, y, palette[z])
			}
		}
	}
	//fmt.Println("Summary:")
	//fmt.Printf("\tmax. avalanches: %v\n", sp.maxAvalanches);
	//fmt.Printf("\t#avalanches: %v\n", sp.avalancheId);
	for _, s := range sp.avalancheId2size {
		_, ok := size2freq[s]

		if !ok {
			size2freq[s] = 1
		} else {
			size2freq[s]++
		}
	}

	sizes := make([]int, len(size2freq)) // to be reverse sorted
	totalFreq := 0
	for s, f := range size2freq {
		fmt.Println(s, f)
		sizes = append(sizes, s)
		totalFreq += f
	}	
	
	sort.Sort(sort.Reverse(sort.IntSlice(sizes)))

	// output cumulative probability distribution
	fDat, _ := os.OpenFile("soc.dat", os.O_WRONLY|os.O_CREATE, 0600)	 
	cumProb := 0.0
	for _, s := range sizes {		
		if s == 0 { // is a problem to represent in logxlog
			break
		}
		fmt.Println(s)
		cumProb += float64(size2freq[s]) / float64(totalFreq)
		fDat.WriteString(strconv.FormatInt(int64(s), 10)+"\t"+ strconv.FormatFloat(cumProb, 'f', 6, 64) + "\n")
	}
	fDat.Close()

	// Generate GIF
	fGif, _ := os.OpenFile("soc.gif", os.O_WRONLY|os.O_CREATE, 0600)
	defer fGif.Close()
	gif.EncodeAll(fGif, &gif.GIF{
		Image: images,
		Delay: delays,
	})
}

