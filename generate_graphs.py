#!/usr/bin/env python3
'''
generate_graphs - generate function calls graphs from linux kernel

=head1 DESCRIPTION

C<generate_graphs> download linux kernel source files from kernel.org, 
generate call graphs using C<cflows> and write them into a file in a 
format suitable for graph description.

This script may be used for pre-processing only. It can be ignored if 
the files' integrity of graph descriptions in 'data' directed were right.

TODO: generate checksum from data
'''
import collections
import os
import pathlib
import re
import subprocess
import tempfile
from urllib.parse import urlparse
from shutil import which

import logging
# Messages logging
logging.basicConfig(level=logging.DEBUG)

# Current directory
curdir = pathlib.Path().absolute()

# Temporary directory to save linux kernel code files
# from different kernel versions.
tmpdir = tempfile.TemporaryDirectory()

# TODO: read datadir from config file
DATADIR = 'data'

def check_preconditions():
    '''Test if the needed resources to generate the data 
    are available.
    '''
    execs = ["cflow", "lynx"]

    for _x in execs:
        if which(_x) is None:
            logging.error('%s not found, please install it.', _x)

def versions_get():
    '''Return an array with the Linux versions listed in the
        file 'versions.txt', one per line.
        Line comments begin with '#'.
        The versions to be downloaded are listed in the file 'versions.txt'.
    '''
    versions = []
    _fn = os.path.join(curdir, "versions.txt")

    _f = open(_fn)
    for _ln in _f.readlines():
        if _ln.startswith('#'):
            continue
        ver = _ln.strip()
        versions.append(ver)
    _f.close()
    return versions

def exec_cmd(cmd_and_args):
    '''Execute a command in the system and return the
    stardard output lines as an array of strings where
    each array element is a line.
    '''
    logging.debug('executing {}'.format(cmd_and_args))
    out = subprocess.Popen(cmd_and_args,
                           shell=True,
                           stdout=subprocess.PIPE,
                           stderr=subprocess.STDOUT)
    stdout, _ = out.communicate() # stdout, stderr

    lines = stdout.decode("utf-8").split('\n')

    return lines

def download_and_extract_file(url):
    '''Download the file using the url string and unpack it 
    in a base directory.
    '''
    path = None
    basedir = tmpdir.name

    logging.info('downloading and extracting %s', url)
    _a = urlparse(url)
    # Set the output file name concatenating temporary dir
    # name and the file name part of the URL
    _fn = os.path.join(basedir, os.path.basename(_a.path))

    # Download file
    exec_cmd(['wget -q ' + url + ' -P ' + basedir])

    # Unpack file
    logging.debug('unpacking %s', _fn)
    exec_cmd(['tar xfJ ' + _fn + ' -C ' + basedir])

    # Return name of unpacked dir that is the name of file
    # without 'tar.xz'
    path = re.sub(r"\.tar\.xz$", "", _fn)
    assert path

    # Some files are uncompressed into 'linux' only directory
    # name without the version part.
    # We add the version part to avoid conflict
    # between the versions with the same property.
    _tmpdir = os.path.join(tmpdir.name, 'linux')
    exec_cmd(['[ -d {dir} ] && mv -v {dir} {path}'
              .format(dir=_tmpdir, path=path)])

    return path

class Indexer():
    '''Used to wrap indexing and mapping operations.
    '''
    def __init__(self):
        self._count = 0
        self._index = {}

    def __len__(self):
        '''Return the number of indexed elements.
        '''
        return len(self._index)

    def index(self, key):
        '''Assign the next available count to become key
        index.
        '''
        idx = -1
        if key not in self._index:
            idx = self._count
            self._index[key] = idx
            self._count = self._count + 1
        else:
            idx = self._index[key]

        assert idx >= 0
        return idx

    def get_dict(self):
        '''Return the dictionary where the vertices are the keys
        and the adjacency list are the values.
        '''
        return self._index

def adj_save(name, index_dict, adj_list):
    '''Save the adjacency list to a data file.
    '''
    # Data file extension
    extension = 'dat'
    # Arcs separator
    asep = ' '

    _fn = os.path.join(DATADIR, '{}.{}'.format(name, extension))

    _f = open(_fn, 'w')
    _f.write('* vertices' + ' ' + '{}'.format(len(index_dict)) + '\n')
    for funcname, idx in index_dict.items():
        _f.write(str(idx) + ' ' + funcname + '\n')
    _f.write('\n')
    _f.write('* arcs\n')
    for u in collections.OrderedDict(sorted(adj_list.items())):
        vs = adj_list[u]
        _f.write(str(u) + ',' + str(len(vs)) + ':')
        for i, v in enumerate(vs):
            if i: # write separator if it is not the 0th element
                _f.write(asep)
            _f.write(str(v))
        _f.write('\n')
    _f.close()
    logging.info('wrote %s', _fn)

def generate_graphs():
    '''Generate an output containing a graph description of 
    function calls obtained from the downloaded source code.
    '''
    # Download the source code files of linux kernel.    
    baseurl = 'https://mirrors.edge.kernel.org/pub/linux/kernel'
    # In the 'versions.txt' file there is only major versions like
    # 'v5.x' for example. The minor version is retrieved from the 
    # content of major version directory.
    for major_ver in versions_get():
        # :TODO: check version string
        # Augment base URL with kernel version
        baseurl = baseurl + '/' + major_ver
        logging.info('processing major version %s', major_ver)

        # List compressed kernel ('*.tar.xz') remote files.
        urls = exec_cmd(['lynx -dump {}'
                         ' | grep tar.xz'
                         ' | grep https'
                         ' | grep -v bdflush'.format(baseurl)])

        # Download files and uncompress remote files.
        for url in urls:
            # Index of current callee function being parsed
            cur_callee = -1

            # Index all functions
            indexer = Indexer()             
            # Map callee to called functions
            callee_to_called = {}
            # Remove numbering and mark at URL left side
            url = re.sub(r"^\s+\d+\.\s+", "", str(url))

            # Download remote file of a kernel version.
            path = download_and_extract_file(url)            

            # Run cflow to extract the funcion calls
            cfiles = exec_cmd(['find ' + path + ' -name *.c'])
            for cfile in cfiles:
                if not cfile:
                    continue

                print(cfile)
                funcs = exec_cmd(['cflow --depth 2 --omit-arguments {}'.format(cfile)])
                for func in funcs:
                    if _m := re.match(r"\s+(\w+)\(\).*", func):
                        funcname = _m.group(1)
                        idx = indexer.index(funcname)
                        print(str(cur_callee) + ' ' + funcname + ' ' + str(idx))
                        callee_to_called[cur_callee].append(idx)
                        print('\t' + funcname)
                    elif _m := re.match(r"(\w+)\(\).*", func):
                        funcname = _m.group(1)
                        idx = indexer.index(funcname)                        
                        if idx not in callee_to_called:
                            cur_callee = idx

                            callee_to_called[cur_callee] = []
                        print(funcname)
                    else:
                        logging.info('no group for {}'.format(func))

            # Get the last part of directory name
            kernel = pathlib.PurePath(path)
            adj_save(kernel.name, indexer.get_dict(), callee_to_called)

if __name__ == '__main__':
    check_preconditions()
    generate_graphs()
