import sys


class Outcome:
    '''Outcome of one run of a sampled application.'''

    def exit(self):
        '''Propagate exit status out to whoever ran this wrapper script.'''
        sys.exit(self.signal or self.status)

    def upload_headers(self):
        '''Contribute additional headers to report uploads.'''
        return {'seed' : str(self.seed),
                'sparsity' : str(self.sparsity),
                'exit-status' : str(self.status),
                'exit-signal' : str(self.signal)}
