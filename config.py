'''Configuration attributes are separated to help
in their modification by looking like a configuration
file where "key=value" set is conventional.
'''
import tempfile

# Where to download the source code files of linux kernel.
BASEURL = 'https://mirrors.edge.kernel.org/pub/linux/kernel'

# Return the name of the directory to save data files.
DATADIR = 'data'

# Extension for generated data files.
DATA_FILE_EXT = 'dat'

# What symbol is used to separate the vertices in the
# adjacency list.
GRAPH_ARC_SEP = ' '

# What symbol is used to separate the vertex index and
# its name in the data file.
GRAPH_INDEX_SEP = ' '

# Temporary directory to save linux kernel code files
# from different kernel versions.
TMPDIR = tempfile.TemporaryDirectory().name
