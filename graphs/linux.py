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

# Local import
from .config import Config
from .db import DB

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

class Linux():
    name = 'linux'
    baseurl = 'https://mirrors.edge.kernel.org/pub/linux/kernel/'

    def __init__(self, kernel_tar_xz_url):
        check_preconditions()
        self._cfg = Config()
        self._tmpdir = self._cfg.get_tmpdir()
        self._db_dir = os.path.join(self._cfg.get_data_dir(),
                                      Linux.name)

        self._tar_xz_url = kernel_tar_xz_url
        # The path where the file downloaded from url is unpacked.
        _a = urlparse(self._tar_xz_url)
        kernel_tar_xz_path = \
            os.path.join(self._tmpdir, os.path.basename(_a.path))
        self._tar_xz_path = kernel_tar_xz_path
        # Relative path of compressed file without 'tar.xz'
        path = re.sub(r"\.tar\.xz$", "", self._tar_xz_path)
        # Version string used to identify the graph, we just remove
        # the "linux-" prefix from directory name.
        version = re.sub(r"linux-", "", pathlib.PurePath(path).name)
        self._version = version
        # Directory where the kernel files are unpacked.
        self._kernel_dir = os.path.join(self._tmpdir, self._version)

    def get_kernel_dir(self):
        '''Return the path where the C files were unpacked.
        '''
        return self._kernel_dir

    def get_db_path(self):
        '''Return the database file name where the graph
        description is saved.
        '''
        db_fn = os.path.join(self._db_dir,
                              DB.add_filename_suffix(self._version))
        return db_fn

    def exists(self):
        '''Return true if the data file already was generated.
        '''
        return os.path.isdir(self._db_dir)

    def get_version(self):
        '''Return the version used to identify the kernel data.
        '''
        return self._version

    def get_tar_xz_path(self):
        '''Return only the relative path of compressed file containing
        the code.
        '''
        return self._tar_xz_path

    def get_tar_xz_url(self):
        '''Return the URL of tar.xz file containing the source code.
        '''
        return self._tar_xz_url

    def db_write_graph(self, indexer, adj_list):
        '''Save the adjacency list to a data file.
        '''
        index_dict = indexer.get_dict()

        gdb = db.open(self._db_path)
        # Start of vertices traversal

        for funcname, idx in index_dict.items():
            _print(str(idx) + funcname + '\n')

        # Begining of adjacency list (arcs) writing.
        for _u in collections.OrderedDict(sorted(adj_list.items())):
            _vs = adj_list[_u]
            dbh.write(str(_u) + ',' + str(len(_vs)) + ':')
            for i, _v in enumerate(_vs):
                _f.write(str(_v))
        logging.info('wrote database files into %s', self._db_dir)

def download_and_extract_file(linux):
    '''Download the file using the url string and unpack it
    in a base directory.
    '''
    url = linux.get_tar_xz_url()
    tar_xz_fn = linux.get_tar_xz_filename()
    logging.info('downloading and extracting %s', url)

    # Download file
    exec_cmd(['wget -q ' + url + ' -P ' + linux.get_tmpdir()])

    # Unpack file
    logging.debug('unpacking %s', tar_xz_fn)
    exec_cmd(['tar xfJ ' + tar_xz_fn + ' -C ' + linux.get_tmpdir()])

    # Some files are uncompressed into 'linux' only directory
    # name without the version part.
    # We add the version part to avoid conflict
    # between the versions with the same property.
    _tmpdir = os.path.join(linux.get_tmpdir(), 'linux')
    exec_cmd(['[ -d {dir} ] && mv -v {dir} {path}'
              .format(dir=_tmpdir, path=data.get_code_path())])

class Indexer():
    '''Used to wrap indexing and mapping operations.
    '''
    def __init__(self):
        self._count = 0
        self._index = {}
        # Count the total number of characters of the
        # indexed keys.
        self._nchars = 0

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
            # The number of characters in "key" + 1 to take into
            # account the NULL terminator in the C programs.
            self._nchars = self._nchars + len(key) + 1
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

    def get_dict(self):
        '''Return the dictionary where the vertices are the keys
        and the adjacency list are the values.
        '''
        return self._index

def get_linux_versions():
    '''Return an array with the Linux versions listed in the
    file "graphs.conf" in the section "linux".
    '''
    cfg = Config()
    return cfg.get_list(Linux.name, 'versions')

def exec_cflow_and_write_data(linux):
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
    cfiles = exec_cmd(['find ' + linux.get_kernel_dir()
                       + ' -name *.c'])
    for cfile in cfiles:
        if not cfile:
            continue

        logging.debug('cflow %s', cfile)
        funcs = exec_cmd(['cflow --depth 2 --omit-arguments {}'.format(cfile)])
        for func in funcs:
            if _m := re.match(r"\s+(\w+)\(\).*", func):
                funcname = _m.group(1)
                idx = indexer.index(funcname)
                callee_to_called[cur_callee].append(idx)
                logging.debug('\tv> %d.%s', idx, funcname)
            elif _m := re.match(r"(\w+)\(\).*", func):
                funcname = _m.group(1)
                idx = indexer.index(funcname)
                if idx not in callee_to_called:
                    cur_callee = idx

                    callee_to_called[cur_callee] = []
                    logging.debug('u> %d.%s', cur_callee, funcname)
            else:
                logging.info('no group for %s', func)

    linux.db_write_graph(indexer, callee_to_called)

def generate_graphs():
    '''Generate an output containing a graph description of
    function calls obtained from the downloaded source code.
    '''
    # In the 'graphs.conf' linux section file there is
    # only major versions like 'v5.x' for example.
    # The minor version is retrieved from the
    # content of major version directory.
    for major_ver in get_linux_versions():
        # :TODO: check version string
        # Augment base URL with kernel version
        baseurl = Linux.baseurl + '/' + major_ver
        logging.info('processing major version %s', major_ver)

        # List compressed kernel ('*.tar.xz') remote files.
        urls = exec_cmd(['lynx -dump {}'
                         ' | grep tar.xz'
                         ' | grep https'
                         ' | grep -v bdflush'
                         ' | grep -vi changelog'
                         ' | grep -vi modules'
                         ' | grep -v patch'
                         ' | grep -v v1.1.0'.format(baseurl)])

        for url in urls:
            if not url:
                continue

            # Remove numbering and mark at URL left side
            url = re.sub(r"^\s+\d+\.\s+", "", str(url))

            lnx = Linux(url)
            if not lnx.exists():
                # Download remote file of a kernel version.
                download_and_extract_file(lnx)
                exec_cflow_and_write_data(lnx)
            else:
                logging.info('database for %s already exists',
                             lnx.get_version())
