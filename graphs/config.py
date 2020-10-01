'''This module intended to be the unique entry to
read configuration values and convert them to other
ways to access becoming them read-only.
'''

import ast
import configparser
import tempfile

class Config:
    '''Read the configuration file "graphs.conf" and
    become the content easily available to different
    formats.
    '''
    def __init__(self):
        self._mate = configparser.ConfigParser()
        self._mate.read('graphs.conf')
        self._data_dir = 'DATA_DIR'

    def get_data_dir(self):
        '''Return the data directory set in the configuration
        file.
        '''
        return self._mate['root'][self._data_dir]

    def get_list(self, context, key):
        '''Return a list for the key in the context section
        using ast.literal() to convert the string to list.
        '''
        return ast.literal_eval(self._mate[context][key])

    def quote(self, strval):
        '''Surround a string value with double quotes.
        '''
        return '"' + strval + '"'

    def get_tmpdir(self):
        '''Return temporary directory to be used by any project.
        '''
        return tempfile.TemporaryDirectory().name

    # TODO: decide where and when to run write_c_header
    def write_c_header(self):
        '''Write a C header file with the configuration
        contents of "graphs.conf".
        '''
        warn = '''/* Dont edit this file,
               it is automatically created. */\n'''

        _f = open('config.h')
        _f.write(warn + '\n')
        _f.write('#include ' +  self.quote(self._data_dir)
                 + self.get_data_dir() + '\n')
        _f.close()