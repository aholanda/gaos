#!/usr/bin/env python3
'''
Generate function calls graphs from linux kernel

This script download linux kernel source files from kernel.org,
generate call graphs using C<cflows> and write them into a file in a
format suitable for graph description.

This script may be used for pre-processing only. It can be ignored if
the files' integrity of graph descriptions in 'data' directed were right.
'''
import collections
import logging
import os
import pathlib
import re
import subprocess
from urllib.parse import urlparse
from shutil import which

TMPDIR = '/tmp'

# Assign the path where this script is running.
CURDIR = pathlib.Path().absolute()

# Messages logging
logging.basicConfig(level=logging.DEBUG)

def check_preconditions():
    '''Test if the needed resources to generate the data
    are available.
    '''
    execs = ["cflow", "lynx", "wget"]

    for _x in execs:
        if which(_x) is None:
            logging.error('%s not found, please install it.', _x)

class Indexer():
    '''Used to wrap indexing and mapping operations.
    '''
    def __init__(self, name):
        self._name = name
        # Counter to get the next available index integer
        self._count = 0
        # Map a name and its index
        self._index = {}
        # Adjacency list: map source vertex identification to
        # destination vertex identification
        self._adj_list = {}
        # Count all tuples in all adjaceny lists.
        self._nadjs = 0

    def get_adj_list(self):
        '''Return the adjacency lists.
        '''
        return self._adj_list

    def get_name(self):
        '''Return the name associated with the indexer.
        '''
        return self._name

    def nindices(self):
        '''Return the number of indices.
        '''
        return self._count

    def nadjs(self):
        '''Return the number of tuples in all adjacency
        lists.
        '''
        return self._nadjs

    def index(self, key):
        '''Assign the next available count to become key
        index.
        '''
        idx = -1
        if key not in self._index:
            # Get the next available count number
            idx = self._count
            # Assign the index number to "key" using a dictionary.
            self._index[key] = idx
            # Increment to the next available index
            self._count = self._count + 1
        else:
            idx = self._index[key]

        assert idx >= 0
        return idx

    def adj_add(self, _from, _to):
        '''Add the tuple <_from, _to> in the adjacency list.
        '''
        if _from not in self._adj_list:
            self._adj_list[_from] = []

        self._adj_list[_from].append(_to)
        self._nadjs = self._nadjs + 1

    def get_dict(self):
        '''Return the dictionary where the vertices are the keys
        and the adjacency list are the values.
        '''
        return self._index

def get_linux_versions():
    '''Return an array with the Linux versions listed in the
    file "graphs.conf" in the section "linux".
    '''
    _vers = []

    _f = open('linux/versions.txt', 'r')
    for _ln in _f.readlines():
        if _ln.startswith('#'):
            continue
        _ln.strip()
        _vers.append(_ln)

    return _vers

def exec_cmd(cmd_and_args):
    '''Execute a command in the system and return the
    stardard output lines as an array of strings where
    each array element is a line.
    '''
    assert cmd_and_args

    logging.debug('executing %s', cmd_and_args)
    out = subprocess.Popen(cmd_and_args,
                           shell=True,
                           stdout=subprocess.PIPE,
                           stderr=subprocess.STDOUT)
    stdout, _ = out.communicate() # stdout, stderr

    lines = stdout.decode("utf-8").split('\n')

    return lines

def request_kernel_tar_xz_urls(version):
    '''The linux kernel version is appended to the linux
    repository base url to retrieve information about the
    compressed files with the kernel. The information is
    retrieved by performing a HTTP(S) request and only the
    files with extension "tar.xz" are filtered using
    shell pipe and command C<grep>. Some reverse patterns are used
    with C<grep> to exclude files other than the kernel ones.
    The output is something like

    14. https://mirrors.edge.kernel.org/pub/linux/kernel/v1.0/linux-1.0.tar.xz

    so C<awk> program is used to extract the URL part.
    The new line in the URL is removed by using the shell command C<tr>.'''
    assert version
    version = version.strip() # remove new line
    baseurl = "https://mirrors.edge.kernel.org/pub/linux/kernel"
    grep_filter = '''| grep tar.xz | grep https | grep -v bdflush \
        | grep -vi changelog | grep -vi modules | grep -v patches \
        | grep -v v1.1.0 | awk \'{print $2}\' | tr -d \'\\n\''''

    cmd = "lynx -dump {}/{} {}".format(baseurl, version, grep_filter)

    return exec_cmd(cmd)

def download_and_extract_kernel(url):
    '''The compressed file with kernel source code is downloaded
    using the command C<wget>. All files are downloaded in a
    temporary directory.

    Returns:
    --------
    The graph name is extracted from the URL by getting its basename
    that represents the downloaded file, and removing the extension
    "tar.xz". In the URL used as an example before,
    the graph name would be "linux-1.0".'''
    assert url
    # download compressed file
    exec_cmd('wget -q {} -P {}'.format(url, TMPDIR))

    # get tar.xz file name from URL
    tar_xz = exec_cmd('basename {}'.format(url))

    # unpack tar.xz
    exec_cmd('tar xfz {} -C {}'.format(tar_xz, TMPDIR))

    # kernel the kernel name from URL, e.g., "linux-1.0"
    # the 2nd element returned would be ''
    kernel_name = exec_cmd('basename {} .tar.xz'.format(url))
    kernel_name = kernel_name[0]

    assert kernel_name
    # Some files are unpacked into directory base name ``linux''
    # without the version part. We add the version part to
    # differentiate it.
    exec_cmd('[ -d {tmp}/linux ] && mv -v {tmp}/linux {tmp}/{graph}'
             .format(tmp=TMPDIR, graph=kernel_name))

    return kernel_name

def exec_cflow(kernel_name):
    '''Execute cflow program to print function call from
    C code, parse the program output and write the
    functions as vertices and called functions as arcs
    (adjacency list) to compose a graph description.
    '''
    assert kernel_name
    # Index of current callee function being parsed
    cur_callee = -1
    # Index all functions
    indexer = Indexer(kernel_name)

    print(kernel_name)
    kernel_dir = os.path.join(TMPDIR, kernel_name)
    # Run cflow to extract the funcion calls
    cfiles = exec_cmd(['find ' + kernel_dir
                       + ' -name \*.c'])
    for cfile in cfiles:
        if not cfile:
            continue

        logging.debug('cflow %s', cfile)
        funcs = exec_cmd(['cflow --depth 2 --omit-arguments {}'.format(cfile)])
        for func in funcs:
            if _m := re.match(r"\s+(\w+)\(\).*", func):
                funcname = _m.group(1)
                idx = indexer.index(funcname)
                # add new pair to adj list
                indexer.adj_add(cur_callee, idx)
                logging.debug('\tv> %d.%s', idx, funcname)
            elif _m := re.match(r"(\w+)\(\).*", func):
                funcname = _m.group(1)
                idx = indexer.index(funcname)
                cur_callee = idx
                logging.debug('u> %d.%s', cur_callee, funcname)
            else:
                logging.info('no group for %s', func)

    return indexer

def write_data(indexer):
    '''Write the graph description into data directory.

    Parameter:
    ----------
    indexer : Indexer object with the vertices' indices
              adjacency list.
    '''
    index_dict = indexer.get_dict()
    adj_list = indexer.get_adj_list()

    _fn = 'data/{}{}'.format(indexer.get_name(), '.dat')
    _f = open(_fn, 'w')
    _f.write('nvertices=' + str(indexer.nindices()) + '\n')
    _f.write('narcs=' + str(indexer.nadjs()) + '\n')
    _f.write('* vertices\n')
    for funcname, idx in index_dict.items():
        _f.write(str(idx) + ' ' + funcname + '\n')

    # Begining of adjacency list (arcs) writing.
    _f.write('\n* arcs\n')
    for _u in collections.OrderedDict(sorted(adj_list.items())):
        _vs = adj_list[_u]
        _f.write(str(_u) + ':')
        for _i, _v in enumerate(_vs):
            _f.write(str(_v))
            if _i+1 != len(_vs):
                _f.write(',')
        _f.write('\n')
    _f.close()
    logging.info('wrote data files into %s', _fn)

    _md5 = 'data/{}{}'.format(indexer.get_name(), '.md5')
    os.system('[ `which md5sum` ] && md5sum {fn} > {md5} && echo "... checksum {md5}"'
              .format(fn=_fn, md5=_md5))

if __name__ == '__main__':
    for version in get_linux_versions():
        urls = request_kernel_tar_xz_urls(version)

        for url in urls:
            kname = download_and_extract_kernel(url)
            idxer = exec_cflow(kname)
            write_data(idxer)
        
        break
