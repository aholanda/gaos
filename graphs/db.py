
import os

from bsddb3 import db

# local
from .config import Config

class DB():
    '''Wrap database operations performed on graph
    elements. The structure of database is the same
    for all graphs. The source of reading may vary and
    for each project may be developed a specific parser
    to separate the graph elements and write them into
    a common database structure.
    '''
    FILENAME_SUFFIX = 'db'

    def __init__(self, proj_name, graph_name='graph'):
        '''
        Parameters
        ----------
        basedir : str
            The name to be appended to data directory composing
            the directory name used to save the database files.
            Commonly is the name of the project. It helps to
            differentiate the database files from one project to
            another. For example, if the data directory name is
            "data" and the project name is "foo", the directory
            used to save the database files for the graphs of "foo"
            will be "data/foo".
        '''
        cfg = Config()
        self._basedir = os.path.join(cfg.get_data_dir(), proj_name)
        self._preffix = graph_name
        self._index_db = \
            DB.add_filename_suffix(os.path.join(self._basedir,
                                                'index'))
        self._index_db_fn = \
            DB.add_filename_suffix(os.path.join(self._basedir,
                                                self._preffix))
        self._vertex_db_fn = \
            DB.add_filename_suffix(os.path.join(self._basedir,
                                                'vertex-' +
                                                self._preffix))
        self._arc_db_fn = \
            DB.add_filename_suffix(os.path.join(self._basedir,
                                                'arc-' +
                                                self._preffix))
        self._index_bdb = db.DB()
        self._index_bdb.open(self._index_db_fn, dbtype=db.DB_HASH,
                             flags=db.DB_CREATE)

    @classmethod
    def add_filename_suffix(cls, filename):
        return filename + '.' + cls.FILENAME_SUFFIX

    