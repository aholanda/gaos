#!/usr/bin/env python3

'''
generate_graphs - generate function calls graphs from linux kernel

=head1 DESCRIPTION

C<generate_graphs> download linux kernel source files from kernel.org, 
generate call graphs using C<cflows> and write them into a file in a 
format suitable for graph description.

This script may be used for pre-processing only. It can be ignored if 
the files' integrity of graph descriptions in 'data' directed were right.

:TODO: generate checksum from data
'''
import lzma
import os
from pathlib import Path
import re
import subprocess
from urllib.parse import urlparse
import urllib.request

import logging
"Messages logging"
log = logging.getLogger("generate_graphs")
log.setLevel(logging.DEBUG)

import pathlib
"Current directory"
curdir = pathlib.Path().absolute()

import tempfile
'''Temporary directory to save linux kernel code files 
from different kernel versions.'''
tmpdir = tempfile.TemporaryDirectory()

# TODO: read datadir from config file
datadir = 'data'

def check_preconditions():
    execs = "cflow", "lynx" 
    
    from shutil import which
    for x in execs:
        if which(x) is None:
            log.error('{} not found, please install it.'.format(x))

def versions_get():
    '''Return an array with the Linux versions listed in the 
        file 'versions.txt', one per line.
        Line comments begin with '#'.
        The versions to be downloaded are listed in the file 'versions.txt'.
    '''
    versions = []
    fn = os.path.join(curdir, "versions.txt")

    f = open(fn)
    for ln in f.readlines():
        if ln.startswith('#'):
            continue
        ver = ln.strip()
        versions.append(ver)
    f.close()
    return versions

def exec_cmd(cmd_and_args):
    log.debug('executing {}'.format(cmd_and_args))
    out = subprocess.Popen(cmd_and_args,
            shell=True,
            stdout=subprocess.PIPE, 
            stderr=subprocess.STDOUT)
    stdout, stderr = out.communicate()
    lines = str(stdout).split(r'\n')
    return lines

def download_and_extract_file(url):
    path = None

    print(url)
    _a = urlparse(url)
    # Set the output file name
    _fn = os.path.join(tmpdir.name, os.path.basename(_a.path))

    # Download file
    urllib.request.urlretrieve(url, _fn)

    # Unpack file
    log.debug('unpacked {}'.format(_fn))
    lzma.open(_fn)

    # Return name of unpacked dir that is the name of file
    # without 'tar.xz'
    path = re.sub(r"\.tar\.gz$", "", _fn)

    assert(path)
    return path

class Indexer():
    def __init__(self):
        self._count = 0
        self._index = {}
        
    def index(self, key):
        idx = -1
        if key not in self._index:
            idx = self._count
            self._index[key] = idx
            self._count = self._count + 1
        else:
            idx = self._index[key]

        assert(idx >= 0)
        return idx

def adj_save(name, indexer, adj_list):
    # Data file extension
    extension = 'dat'
    fn = os.path.join(datadir, '{}.{}'.format(name, extension))

def generate_graphs():
    versions = versions_get()

    # Download the source code files of linux kernel.    
    baseurl = 'https://mirrors.edge.kernel.org/pub/linux/kernel'
    # In the 'versions.txt' file there is only major versions like
    # 'v5.x' for example. The minor version is retrieved from the 
    # content of major version directory.
    for major_ver in versions:
        # :TODO: check version string
        # Augment base URL with kernel version
        baseurl = baseurl + '/' + major_ver;
        log.info('processing major version {}'.format(major_ver));
    
        # List compressed kernel ('*.tar.xz') remote files.
        urls = exec_cmd(['lynx -dump {}'
                                 ' | grep tar.xz'
                                 ' | grep https'
                                 ' | grep -v bdflush'.format(baseurl)])
        
        # Download files and uncompress remote files.
        for url in urls:
            # Remove numbering and mark at URL left side
            url = re.sub(r"^b'\s+\d+\.\s+", "", str(url))
            
            indexer = Indexer()
            # Adjacency list to link vertices and arcs
            adj_list = {}
            # Download remote file of a kernel version.
            path = download_and_extract_file(url)

            # Some files are uncompressed into 'linux' only directory 
            # name without the version part.
            # We add the version part to avoid conflict 
            # between the versions with the same property.
            _tmpdir = os.path.join(tmpdir.name, 'linux')
            new_tmpdir = _tmpdir + '-' + major_ver
            exec_cmd(['[ -d {} ] && mv -v {} {}-{}'
                    .format(_tmpdir, _tmpdir, _tmpdir, new_tmpdir)]);
            
            print(path)
            # Run cflow to extract the funcion calls
            cfiles = exec_cmd(['find', '{}'.format(path), '-name *.c'])
            for cfile in cfiles:
                print(cfile)
                funcs = exec_cmd(['cflow --depth 2 --omit-arguments {}'.format(cfile)])
                print(funcs)
                for func in funcs:
                    if m := re.match(r"\s+(\w+)\(\).*", func):
                        funcname = m.group(1)
                        print(funcname)
                    elif m := re.match(r"(\w+)\(\).*", func):
                        funcname = m.group(1)
                        print(funcname)
                    else:
                        log.info('no group for {}'.format(func))

            #adj_save(indexer, adj_list);
            continue

def cleanup():
    '''Clean all temporary resources like files and directories'''
    tmpdir.cleanup()

if __name__ == '__main__':
    check_preconditions()
    generate_graphs()
    #cleanup()