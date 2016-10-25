from setuptools import Extension, setup
from Cython.Build import cythonize
from sys import platform
from numpy import get_include

from distutils.sysconfig import get_config_vars
import os

(opt,) = get_config_vars('OPT')
if opt:
    os.environ['OPT'] = " ".join(flag for flag in opt.split() if flag != '-Wstrict-prototypes')

incl = ['./include', get_include()]
extrac = []

if platform == 'win32':
    rldirs = []
    extrac.append('/EHsc')
elif platform == 'darwin':
    rldirs = []
else:
    rldirs = ["$ORIGIN"]
    extrac.extend(["-w", "-O3"])

setup(
    name="cycgkit",
    packages=["cycgkit"],
    ext_modules=cythonize([
        Extension('cycgkit/cgtypes/*', ["cycgkit/cgtypes/*.pyx", './src/vec3.cpp'],
                  include_dirs=incl,
                  runtime_library_dirs=rldirs,
                  extra_compile_args=extrac,
                  language="c++")
    ]),
)
