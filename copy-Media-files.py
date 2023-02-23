import re
import shutil
from os import makedirs, path
from glob import glob

pat = re.compile(f'\/Media\/(?P<mid>.*)(?P<name>.*)\.(?P<ext>[^\'"]*)')
pat_fromString = re.compile(f"' \+ \(\$elm\$core\$String\$fromInt\(.+\) \+ '")

makedirs('./dist/Media/', exist_ok=True)

with open('./dist/index.html', 'r') as ifile:
    for line in ifile:
        if m := pat.search(line):
            f = m.group(0)
            # f includes the leading slash
            makedirs(f'./dist{f[:f.rfind("/")]}', exist_ok=True)
            if path.exists(f[1:]):
                shutil.copyfile(f[1:], f'dist{f}')
            elif g := pat_fromString.sub('*', f):
                for f in glob(g[1:]):
                    shutil.copyfile(f, f'dist/{f}')
            else:
                raise IOError('File not found: ' + f)


