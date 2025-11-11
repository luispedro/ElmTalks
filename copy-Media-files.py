import re
import shutil
from os import makedirs, path
from sys import argv
from glob import glob

pat = re.compile(r'\/?Media\/(?P<mid>.*)(?P<name>.*)\.(?P<ext>[^\'"]*)')
pat_stepped = re.compile(r'\/?Media\/(?P<mid>.*)(?P<name>.*)_stepped-')
pat_fromString = re.compile(r"' \+ \(\$elm\$core\$String\$fromInt\(.+\) \+ '")

if len(argv) >= 2:
    target = argv[1]
else:
    target = './dist'

makedirs(f'{target}/Media/', exist_ok=True)

with open(f'{target}/index.html', 'r') as ifile:
    for line in ifile:
        if m := pat.search(line):
            f = m.group(0)
            # normalize f to always include the leading slash
            if f.startswith('Media/'):
                f = '/' + f
            makedirs(f'{target}{f[:f.rfind("/")]}', exist_ok=True)
            if path.exists(f[1:]):
                shutil.copyfile(f[1:], f'{target}{f}')
            elif g := pat_fromString.sub('*', f):
                for f in glob(g[1:]):
                    shutil.copyfile(f, f'{target}/{f}')
            else:
                raise IOError('File not found: ' + f)
        elif m := pat_stepped.search(line):
            f = m.group(0)
            # normalize f to always include the leading slash
            if f.startswith('Media/'):
                f = '/' + f
            makedirs(f'{target}{f[:f.rfind("/")]}', exist_ok=True)
            for f in glob(f'{f[1:]}*'):
                shutil.copyfile(f, f'{target}/{f}')
