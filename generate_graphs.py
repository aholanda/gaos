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
    logging.debug('executing %s', ' '.join(cmd_and_args))
    out = subprocess.Popen(cmd_and_args,
                           shell=True,
                           stdout=subprocess.PIPE,
                           stderr=subprocess.STDOUT)
    stdout, _ = out.communicate() # stdout, stderr

    lines = stdout.decode("utf-8").split('\n')

    return lines

class Data():
    '''Wrap operations on data like concatenation of
    data directory and file name, data file existence
    and data writing. This class also handle the tokens
    separators for graph description.
    '''
    def __init__(self, tar_xz_url, basedir='data',
                 file_extension='dat',
                 arc_separator=' '):
        self._basedir = basedir
        self._file_extension = file_extension
        self._url = tar_xz_url
        # The path where the file downloaded from url is unpacked.
        _a = urlparse(tar_xz_url)
        path = os.path.join(tmpdir.name, os.path.basename(_a.path))
        self._tar_xz_file = path
        # Relative path of compressed file without 'tar.xz'
        path = re.sub(r"\.tar\.xz$", "", path)
        self._checksum_data_file = \
            os.path.join(basedir, 
                         pathlib.PurePath(path).name + '.' + 'md5')
        self._code_path = os.path.join(tmpdir.name, path)
        self._data_file = \
            os.path.join(basedir,
                         pathlib.PurePath(path).name
                         + '.' + self._file_extension)
        self._arc_sep = arc_separator

    def get_code_path(self):
        '''Return the path where the C files were unpacked.
        '''
        return self._code_path

    def get_filename(self):
        '''Return the data file name where the graph description
        is saved.
        '''
        return self._data_file

    def file_exists(self):
        '''Return true if the data file already was generated.
        '''
        print(self._data_file)
        return os.path.isfile(self._data_file)

    def get_tar_xz_filename(self):
        '''Return only the relative path of compressed file containing
        the code.
        '''
        return self._tar_xz_file

    def get_url(self):
        '''Return the URL of tar.xz file containing the source code.
        '''
        return self._url

    def generate_checksum(self):
        exec_cmd(['md5sum ' + self._data_file + ' > '\
                  + self._checksum_data_file])

    def save(self, index_dict, adj_list):
        '''Save the adjacency list to a data file.
        '''
        _f = open(self._data_file, 'w')
        _f.write('* vertices' + ' ' + '{}'.format(len(index_dict)) + '\n')
        for funcname, idx in index_dict.items():
            _f.write(str(idx) + ' ' + funcname + '\n')
        _f.write('\n')
        _f.write('* arcs\n')
        for _u in collections.OrderedDict(sorted(adj_list.items())):
            _vs = adj_list[_u]
            _f.write(str(_u) + ',' + str(len(_vs)) + ':')
            for i, _v in enumerate(_vs):
                if i: # write separator if it is not the 0th element
                    _f.write(self._arc_sep)
                _f.write(str(_v))
            _f.write('\n')
        _f.close()
        self.generate_checksum()
        logging.info('wrote %s', self._data_file)

def download_and_extract_file(data):
    '''Download the file using the url string and unpack it
    in a base directory.
    '''
    url = data.get_url()
    tar_xz_fn = data.get_tar_xz_filename()
    logging.info('downloading and extracting %s', url)

    # Download file
    exec_cmd(['wget -q ' + url + ' -P ' + tmpdir.name])

    # Unpack file
    logging.debug('unpacking %s', tar_xz_fn)
    exec_cmd(['tar xfJ ' + tar_xz_fn + ' -C ' + tmpdir.name])

    # Some files are uncompressed into 'linux' only directory
    # name without the version part.
    # We add the version part to avoid conflict
    # between the versions with the same property.
    _tmpdir = os.path.join(tmpdir.name, 'linux')
    exec_cmd(['[ -d {dir} ] && mv -v {dir} {path}'
              .format(dir=_tmpdir, path=data.get_code_path())])

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

def exec_cflow_and_write_data(data):
    '''Execute cflow program to print function call from
    C code, parse the program output and write the
    functions as vertices and called functions as arcs
    (adjacency list) to compose a graph description.
    '''
    # Index of current callee function being parsed
    cur_callee = -1
    # Index all functions
    indexer = Indexer()
    # Map callee to called functions
    callee_to_called = {}

    # Run cflow to extract the funcion calls
    cfiles = exec_cmd(['find ' + data.get_code_path() + ' -name *.c'])
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
                logging.info('no group for %s', func)

    data.save(indexer.get_dict(), callee_to_called)

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

        for url in urls:
            if not url:
                continue

            # Remove numbering and mark at URL left side
            url = re.sub(r"^\s+\d+\.\s+", "", str(url))

            data = Data(url)
            if not data.file_exists():
                # Download remote file of a kernel version.
                download_and_extract_file(data)
                exec_cflow_and_write_data(data)
            else:
                logging.info('file %s already exists',
                             data.get_filename())

    
if __name__ == '__main__':
    check_preconditions()
    generate_graphs()
