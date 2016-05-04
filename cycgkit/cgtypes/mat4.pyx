from cpython cimport Py_buffer

cdef _supported_ = ['list with 3 numbers',
                         '3 lists with 3 numbers each',
                         '1 vec3',
                         '3 vec3',
                         'mat4',
                         '1 number',
                         '9 numbers',
                         '2-D numpy array',
                         '1.0 for identity',
                         'empty args']


cdef class mat4:
    def __cinit__(self, *args):
        cdef short argLen = len(args)
        cdef type otype = type(args[0]) if argLen > 0 else None
        self.items = 16
        self.ncols = 4
        self.nrows = 4
        self.isTransposed = False

        if argLen == 0:
            # no arguments
            self.cvec = mat4_f()
        elif otype is mat4:
            # copy from mat4
            self.cvec = (<mat4>args[0]).cvec
        elif 'numpy.ndarray' in str(otype):
            # from numpy array
            if args[0].ndim == 2:
                self.cvec = mat4.from_3iterable_of3([args[0][0], args[0][1], args[0][2]])
            else:
                raise TypeError('for matrices, Numpy arrays should be 2-D')
        elif otype is vec3:
            # from vec3
            if argLen == 1:
                # 1 vec
                self.cvec = mat4_f()
                for r in range(3):
                    self.cvec.setColumn(r, (<vec3>args[0]).cvec)
            elif argLen == 3:
                # 3 vecs
                self.cvec = mat4_f()
                for r in range(3):
                    self.cvec.setColumn(r, (<vec3>args[r]).cvec)
            else:
                raise TypeError('Wrong number of arguments. Expected {} got {}'.format(self.nrows, len(args)))
        elif argLen == self.items:
            # from 9 explicit doubles or ints
            self.cvec = mat4.from_9double(args)
        elif argLen == self.nrows:
            # from 3 explicit elements
            if getattr(args[0], '__getitem__', None) and len(args[0]) == 3:
                # of 3
                self.cvec = mat4.from_3iterable_of3(args)
            else:
                # of 1
                self.cvec = mat4.from_1iterable_of3(args)
        elif argLen == 1 and type(args[0]) in [int, float]:
            # from single double or int
            if args[0] == 1.0:
                # as identity if arg == 1.0
                self.cvec = mat4_f().setIdentity()
            else:
                # 1 repeated double or int
                self.cvec = mat4_f(<double>args[0])
        elif argLen == 1 and otype is list:
            # from list with unknown stuff inside
            self.cvec = mat4(*args[0]).cvec
        else:
            raise TypeError('Wrong number/type of arguments. Expected one of the following:\n{}\ngot {} {}'.format(
                '\n'.join(['- ' + str(s) for s in _supported_]), argLen, otype))

    @staticmethod
    cdef mat4_f from_1iterable_of3(object it3):
        cdef mat4_f tcvec = mat4_f()
        for r in range(3):
            tcvec.setColumn(r, vec3_f(it3[0], it3[1], it3[2]))
        return tcvec

    @staticmethod
    cdef mat4_f from_3iterable_of3(object it3):
        cdef mat4_f tcvec = mat4_f()
        for r in range(3):
            tcvec.setColumn(r, vec3_f(it3[r][0], it3[r][1], it3[r][2]))
        return tcvec

    @staticmethod
    cdef mat4_f from_9double(object it9):
        cdef double a, b, c, d, e, f, g, h, i
        a, b, c, d, e, f, g, h, i = it9
        cdef mat4_f tcvec = mat4_f(a, b, c, d, e, f, g, h, i)
        return tcvec

    @staticmethod
    cdef mat4 from_cvec(mat4_f cvec):
        cdef mat4 res = mat4()
        res.cvec = cvec
        return res

    def __mul__(mat4 self, other):
        cdef mat4_f res
        cdef type otype = type(other)
        if otype in [float, int]:
            res = <mat4_f&>self.cvec * (<double>other)
            return mat4.from_cvec(res)
        elif otype == mat4:
            res = <mat4_f&>self.cvec * (<mat4_f&>(<mat4>other).cvec)
            return mat4.from_cvec(res)
        elif otype == vec3:
            return vec3.from_cvec(<mat4_f&>self.cvec * (<vec3_f&>(<vec3>other).cvec))
        elif otype == vec4:
            return vec4.from_cvec(<mat4_f&>self.cvec * (<vec4_f&>(<vec4>other).cvec))
        else:
            raise TypeError("unsupported operand type(s) for *: \'{}\' and \'{}\'".format(mat4, otype))

    def __truediv__(self, other not None):
        cdef mat4_f res
        cdef type otype = type(other)
        if type(self) is not mat4 and otype is mat4:
            raise TypeError('mat4 in the right not supported')
        if otype in [float, int]:
            if other == 0:
                raise ZeroDivisionError("can't divide by 0")
            else:
                res = (<mat4_f&>(<mat4>self).cvec) / (<const double>other)
                return mat4.from_cvec(res)
        else:
            raise TypeError("unsupported operand type(s) for /: \'{}\' and \'{}\'".format(mat4, otype))

    def __div__(self, other not None):
        return self.__truediv__(other)

    def __mod__(mat4 self, other not None):
        """ Return self%value. """
        cdef mat4_f res
        cdef type otype = type(other)
        if otype in [float, int]:
            res = <mat4_f&>self.cvec % (<double>other)
        elif otype == mat4:
            res = <mat4_f&>self.cvec % (<mat4_f&>(<mat4>other).cvec)
        else:
            raise TypeError("unsupported operand type(s) for %: \'{}\' and \'{}\'".format(mat4, otype))
        return mat4.from_cvec(res)

    def __neg__(self):
        cdef mat4 res = mat4()
        res.cvec = -(<mat4_f>self.cvec)
        return res

    def __sub__(self, other not None):
        """ Return self-value. """
        cdef mat4_f res
        cdef type otype = type(other)
        if otype is mat4:
            res = (<mat4_f&>(<mat4>self).cvec) - (<mat4_f&>(<mat4>other).cvec)
            return mat4.from_cvec(res)
        else:
            raise TypeError("unsupported operand type(s) for -: \'{}\' and \'{}\'".format(mat4, otype))

    def __add__(self, other not None):
        """ Return self+value. """
        cdef mat4_f res
        cdef type otype = type(other)
        if otype is mat4:
            res = (<mat4_f&>(<mat4>self).cvec) + (<mat4_f&>(<mat4>other).cvec)
            return mat4.from_cvec(res)
        else:
            raise TypeError("unsupported operand type(s) for +: \'{}\' and \'{}\'".format(mat4, otype))

    def __richcmp__(mat4 self, mat4 other, int f):
        cdef str op
        if f == 0:
            op = '<'
        elif f == 1:
            op = '<='
        if f == 2:
            return self.cvec == other.cvec
        elif f == 3:
            return self.cvec != other.cvec
        elif f == 4:
            op = '>'
        elif f == 5:
            op = '>='

        raise TypeError('operator \'{}\' not defined for {}'.format(op, mat4))

    def tolist(self, rowMajor=False):
        cdef list tl
        cdef vec4_f r0, r1, r2, r3
        if rowMajor:
            r0 = self.cvec.getRow(0)
            r1 = self.cvec.getRow(1)
            r2 = self.cvec.getRow(2)
            r3 = self.cvec.getRow(3)
        else:
            r0 = self.cvec.getColumn(0)
            r1 = self.cvec.getColumn(1)
            r2 = self.cvec.getColumn(2)
            r3 = self.cvec.getColumn(3)

        tl = [r0.x, r0.y, r0.z, r0.w,
              r1.x, r1.y, r1.z, r1.w,
              r2.x, r2.y, r2.z, r2.w,
              r3.x, r3.y, r3.z, r3.w]
        return tl

    def toList(self, rowMajor=False):
        return self.tolist(rowMajor)

    def __len__(mat4 self):
        return self.items

    def __getitem__(self, object index):
        cdef type otype = type(index)
        if otype is int:
            if index > self.nrows - 1:
                raise IndexError
            else:
                return vec4.from_cvec(vec4_f(self.cvec.getColumn(<int>index)))
        elif otype is slice:
            raise TypeError('index must be integer or 2-tuple')
        elif type(index) == tuple:
            return vec4_f(self.cvec.getRow(<int>index[0]))[<int>index[1]]
        else:
            raise TypeError('index must be integer or 2-tuple')

    cdef checkViews(self):
        if self.view_count > 0:
            raise ValueError("can't modify it while being viewed")

    def __setitem__(mat4 self, object key, object value):
        cdef type otype = type(key)
        self.checkViews()
        cdef list rows = []
        cdef int r
        cdef vec4_f nval

        if otype is int:
            if key > self.nrows - 1:
                raise IndexError
            else:
                rows.append(key)
        elif otype is slice:
            for r in range(key.start, key.stop, key.step if key.step is not None else 1):
                rows.append(r)
        elif otype == tuple:
            if type(value) is vec3:
                for r in key:
                    rows.append(r)
            elif type(value) in [float, int]:
                if len(key) > 2:
                    raise ValueError('index tuple must be a 2-tuple')
                self.cvec.getColumn(key[0], nval)
                r = key[1]
                if r == 0:
                    nval.x = value
                elif r == 1:
                    nval.y = value
                elif r == 2:
                    nval.z = value
                elif r == 3:
                    nval.w = value
                else:
                    raise IndexError(r)
                self.cvec.setColumn(key[0], nval)
                return
        else:
            raise TypeError('an integer is required')

        if type(value) is not vec4:
            raise TypeError('a vec4 is required')
        for r in rows:
            self.cvec.setColumn(r, (<vec4>value).cvec)

    def __repr__(self):
        cdef vec4 v = vec4()
        cdef list res = [None, None, None]
        for x in range(4):
            _ = self.getRow(x, v)
            res[x] = v.__repr__() + '\n'
        return ''.join(s for s in res)

    def __sizeof__(self):
        return sizeof(mat4)

    property cSize:
        "Size in memory of c native elements"
        def __get__(self):
            return sizeof(self.cvec)

    def ortho(self, inplace=False):
        '''
        Return this matrix's ortho if inplace=False.
        or Apply ortho to this matrix in place
        '''
        if inplace:
            self.checkViews()
            self.cvec.ortho(self.cvec)
        else:
            return mat4.from_cvec(self.cvec.ortho())

    def __getbuffer__(self, Py_buffer *buffer, int flags):
        if not self.isTransposed:
            self.cvec.transpose(self.cvec)
            self.isTransposed = True
        cdef Py_ssize_t itemsize = sizeof(double)

        self.shape[0] = self.nrows
        self.shape[1] = self.ncols

        # Stride 1 is the distance, in bytes, between two items in a row;
        # this is the distance between two adjacent items in the vector.
        # Stride 0 is the distance between the first elements of adjacent rows.
        cdef long a = <long>&((<vec4_f>self.cvec.getRow(0))[1])
        cdef long b = <long>&((<vec4_f>self.cvec.getRow(0))[0])
        self.strides[1] = <Py_ssize_t>(a - b)
        self.strides[0] = self.ncols * self.strides[1]

        buffer.buf = <double*>(<mat4_f*>&self.cvec)
        buffer.format = 'd'                     # double
        buffer.internal = NULL                  # see References
        buffer.itemsize = itemsize
        buffer.len = self.items * itemsize   # product(shape) * itemsize
        buffer.ndim = 2
        buffer.obj = self
        buffer.readonly = 0
        buffer.shape = self.shape
        buffer.strides = self.strides
        buffer.suboffsets = NULL                # for pointer arrays only
        self.view_count += 1
        #todo: check flags
        '''
        Strictly speaking, if the flags contain PyBUF_ND, PyBUF_SIMPLE, or PyBUF_F_CONTIGUOUS, __getbuffer__ must
        raise a BufferError. These macros can be cimport‘d from cpython.buffer.
        '''

    def __releasebuffer__(self, Py_buffer *buffer):
        self.view_count -= 1
        if self.view_count == 0:
            self.cvec.transpose(self.cvec)
            self.isTransposed = False

    ########################  Advanced methods  ########################

    def at(mat4 self, short i, short j):
        return self.cvec.at(i, j)

    @staticmethod
    def identity():
        cdef mat4 res = mat4()
        res.cvec.setIdentity()
        return res

    # set_ and get_ methods
    def setIdentity(mat4 self):
        self.checkViews()
        self.cvec.setIdentity()

    def setRow(mat4 self, int row, vec4 val):
        self.checkViews()
        self.cvec.setRow(row, val.cvec)

    def setRow(mat4 self, short row, const double a, const double b, const double c, const double d):
        self.checkViews()
        self.cvec.setRow(row, a, b, c)

    def setColumn(mat4 self, int col, vec4 val):
        self.checkViews()
        self.cvec.setColumn(col, val.cvec)

    def setColumn(mat4 self, short col, const double a, const double b, const double c, const double d):
        self.checkViews()
        self.cvec.setColumn(col, a, b, c)

    def setDiag(mat4 self, vec4 val):
        self.checkViews()
        self.cvec.setDiag(val.cvec)

    def setDiag(mat4 self, const double a, const double b, const double c, const double d):
        self.checkViews()
        self.cvec.setDiag(a, b, c, d)

    def getRow(mat4 self, short i, vec4 dest=None):
        cdef double a, b, c, d
        if dest is not None:
            self.cvec.getRow(i, dest.cvec)
        else:
            a = b = c = 0
            self.cvec.getRow(i, a, b, c, d)
            return a, b, c, d

    def getColumn(mat4 self, short i, vec4 dest=None):
        cdef double a, b, c, d
        if dest is not None:
            self.cvec.getColumn(i, dest.cvec)
        else:
            a = b = c = d = 0
            self.cvec.getColumn(i, a, b, c, d)
            return a, b, c, d

    def getDiag(mat4 self, vec4 dest=None):
        cdef double a, b, c, d
        if dest is not None:
            self.cvec.getDiag(dest.cvec)
        else:
            a = b = c = d = 0
            self.cvec.getDiag(a, b, c, d)
            return a, b, c, d

    @staticmethod
    def rotation(double angle, vec3 axis):
        cdef mat4 res = mat4()
        res.cvec.setRotation(angle, axis.cvec)
        return res

    @staticmethod
    def scaling(vec3 scale):
        '''Returns a matrix set to "scale"'''
        cdef mat4 res = mat4()
        res.cvec.setScaling(scale.cvec)
        return res

    def determinant(mat4 self):
        return self.cvec.determinant()

    def inversed(mat4 self):
        '''Returns a copy of this matrix inverse'''
        return mat4.from_cvec(self.cvec.inverse())

    def inverse(mat4 self):
        '''Invert this matrix in place'''
        self.checkViews()
        self.cvec.inverse(self.cvec)

    def transposed(mat4 self):
        '''Returns a copy of this matrix transpose'''
        return mat4.from_cvec(self.cvec.transpose())

    def transpose(mat4 self):
        '''Transpose this matrix in place'''
        self.checkViews()
        self.cvec.transpose(self.cvec)

    def scale(mat4 self, vec3 s):
        '''Scale this matrix for "s"'''
        self.checkViews()
        self.cvec.scale(s.cvec)

    def rotate(mat4 self, double angle, vec3 axis):
        '''Rotate this matrix'''
        self.checkViews()
        self.cvec.rotate(angle, axis.cvec)

    def decompose(mat4 self):
        '''Decompose this matrix into a mat4 for rotation, a
        vec3 for translation and a vec3 for scale'''
        cdef vec3_f t
        cdef mat4_f rot
        cdef vec3_f scale
        self.cvec.decompose(t, rot, scale)
        return vec3.from_cvec(t), mat4.from_cvec(rot), vec3.from_cvec(scale)
