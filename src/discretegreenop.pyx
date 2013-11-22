from cython cimport boundscheck
from cython cimport cdivision
from cython cimport Py_ssize_t
from cython cimport sizeof
from cython cimport wraparound
from cython.view cimport array
from libc.math cimport M_PI
from libc.stdlib cimport malloc
from libc.stdlib cimport free

from greenop cimport GreenOperator

cdef double TWO_PI = 2. * M_PI

cdef str INVALID_SHAPE_MSG = 'length of shape must be {0} (was {1})'
cdef str INVALID_H_MSG = 'h must be > 0 (was {0})'
cdef str INVALID_B_MSG = 'shape of b must be ({0},) [was ({1},)]'

cdef class TruncatedGreenOperator:
    cdef readonly GreenOperator green
    cdef readonly double h
    #TODO Make this readable from Python
    cdef Py_ssize_t *shape
    cdef double[::1] k
    cdef double two_pi_over_h

    @cdivision(True)
    def __cinit__(self, GreenOperator green, tuple shape not None, double h):
        cdef Py_ssize_t d = len(shape)
        if d != green.mat.dim:
            raise ValueError(INVALID_SHAPE_MSG.format(green.mat.dim, d))
        if h <= 0.:
            raise ValueError(INVALID_H_MSG.format(h))
        self.green = green
        self.h = h
        self.two_pi_over_h = TWO_PI / h
        self.k = array(shape=(d,), itemsize=sizeof(double), format='d')
        self.shape = <Py_ssize_t *> malloc(d * sizeof(Py_ssize_t))
        cdef int i
        for i in range(d):
            #TODO Check for sign of shape[i]
            self.shape[i] = shape[i]

    def __dealloc__(self):
        free(self.shape)

    cdef inline void check_b(self, Py_ssize_t[:] b) except *:
    # TODO Improve quality of checks and error messages.
        if b.shape[0] != self.green.mat.dim:
            raise ValueError(INVALID_B_MSG.format(self.green.mat.dim,
                                                  b.shape[0]))
        cdef Py_ssize_t i, ni, bi
        for i in range(self.green.mat.dim):
            ni = self.shape[i]
            bi = b[i]
            if (bi < 0) or (bi >= ni):
                raise ValueError('')

    @boundscheck(False)
    @cdivision(True)
    @wraparound(False)
    cdef void update(self, Py_ssize_t[:] b):
        cdef:
            Py_ssize_t i, ni, bi
            double s
        for i in range(self.green.mat.dim):
            ni = self.shape[i]
            bi = b[i]
            s = self.two_pi_over_h / <double> ni
            if 2 * bi > ni:
                self.k[i] = s * (bi - ni)
            else:
                self.k[i] = s * bi

    cpdef double[:] apply_single_freq(self,
                                      Py_ssize_t[:] b,
                                      double[:] tau,
                                      double[:] eta=None):
        self.check_b(b)
        self.update(b)
        return self.green.apply(self.k, tau, eta)

    cpdef double[:, :, :] apply_all_freqs(self,
                                          double[:, :, :] tau,
                                          double[:, :, :] eta=None):
        # TODO Check size of tau and eta
        """
        if eta is None:
            eta = array(shape=,
                        itemsize=sizeof(double),
                        format='d')
        """
        return eta

    cpdef double[:, :] asarray(self, Py_ssize_t[:] b, double[:, :] a=None):
        self.update(b)
        return self.green.asarray(self.k, a)
