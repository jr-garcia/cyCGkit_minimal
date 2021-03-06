import unittest
from unittest import TestCase, skip, skipIf
import cycgkit.cgtypes as cycg
import cgkit.cgtypes as cg

try:
    import numpy as np

    hasNumpy = True
except ImportError:
    hasNumpy = False


class test(TestCase):
    def setUp(self):
        a = 0, 1.6, 2, 3, 4.977, 5, 6, .007, 8
        b = 0.000921, 10, 20.5
        self.cym = cycg.mat3(*a)
        self.cgm = cg.mat3(*a)
        self.cyvec3 = cycg.vec3(*b)
        self.cgvec3 = cg.vec3(*b)

    def assertEqual(self, first, second, msg=None):
        types = [type(self.cgm), cg._core.mat3, type(self.cym)]
        if type(first) in types and type(second) in types:
            first = first.toList()
            second = second.toList()
            self.assertAlmostEqual(first, second, msg)
        else:
            super(test, self).assertEqual(first, second, msg)

    def test_from9floats(self):
        m1 = cg.mat3(0, 1.6, 2, 3, 4.977, 5, 6, .007, 8)
        m2 = cycg.mat3(0, 1.6, 2, 3, 4.977, 5, 6, .007, 8)
        self.assertEqual(m1, m2)

    def test_from3lists(self):
        m1 = cg.mat3([0, 1.6, 2], [3, 4.977, 5], [6, .007, 8])
        m2 = cycg.mat3([0, 1.6, 2], [3, 4.977, 5], [6, .007, 8])
        self.assertEqual(m1, m2)

    def test_toListRow(self):
        self.assertEqual(self.cgm.toList(True), self.cym.toList(True))

    def test_toListNotRow(self):
        self.assertEqual(self.cgm.toList(False), self.cym.toList(False))

    def test_indexSimple0(self):
        self.assertEqual(list(self.cgm[0]), list(self.cym[0]))

    def test_indexSimple1(self):
        self.assertEqual(list(self.cgm[1]), list(self.cym[1]))

    def test_indexSimple2(self):
        self.assertEqual(list(self.cgm[2]), list(self.cym[2]))

    def test_indexSubindex0(self):
        index = [0, 0]
        self.assertEqual(self.cgm[index[0], index[1]], self.cym[index[0], index[1]])

    def test_indexSubindex1(self):
        index = [0, 1]
        self.assertEqual(self.cgm[index[0], index[1]], self.cym[index[0], index[1]])

    def test_indexSubindex2(self):
        index = [0, 2]
        self.assertEqual(self.cgm[index[0], index[1]], self.cym[index[0], index[1]])

    def test_indexTuple(self):
        index = [0, 2]
        self.assertEqual(self.cgm[index[0], index[1]], self.cym[index[0], index[1]])

    def test_repr(self):
        cystr = repr(self.cym)
        cgstr = repr(self.cgm)
        self.assertEqual(cgstr, cystr)

    def test_multVec3Left(self):
        v1 = self.cgm * self.cgvec3
        v2 = self.cym * self.cyvec3
        self.assertEqual(list(v1), list(v2))

    def test_multVec3Right(self):
        v1 = self.cgvec3 * self.cgm
        v2 = self.cyvec3 * self.cym
        self.assertEqual(list(v1), list(v2))

    @skipIf(not hasNumpy, 'toNumpyArray test skipped. Numpy not found.')
    def test_toNumpyArray(self):
        cgarr = np.asarray(self.cgm)
        cyarr = np.asarray(self.cym)
        self.assertTrue(np.all(np.equal(cgarr, cyarr)))

    def test_SameReturnRotate(self):
        a = self.cgm.rotate(0.5, self.cgvec3)
        b = self.cym.rotate(0.5, self.cyvec3)
        self.assertEqual(a, b)

    def test_SameReturnScale(self):
        a = self.cgm.scale(self.cgvec3)
        b = self.cym.scale(self.cyvec3)
        self.assertEqual(a, b)

    def test_SameReturnTranspose(self):
        a = self.cgm.transpose()
        b = self.cym.transpose()
        self.assertEqual(a, b)

    def test_SameReturnInverse(self):
        a = self.cgm.inverse()
        b = self.cym.inverse()
        self.assertEqual(a, b)

    @skip
    def test_Hash(self):
        a = hash(self.cgm)
        b = hash(self.cym)  # fixme: find out how to return same value if possible
        self.assertEqual(a, b)


if __name__ == '__main__':
    unittest.main()
