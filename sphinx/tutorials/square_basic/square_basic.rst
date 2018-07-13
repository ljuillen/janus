.. -*- coding: utf-8 -*-

******************************
Square inclusion, basic scheme
******************************

Description of the problem
==========================

In this tutorial, we will compute the effective elastic properties of a simple 2D microstructure in plane strain. More precisely, we consider a periodic microstructure made of a square inclusion of size :math:`a`, embedded in a unit-cell of size :math:`L` (see :numref:`fig_microstructure`).

.. _fig_microstructure:
.. figure:: microstructure.*
   :align: center

   The periodic microstructure under consideration.

   :math:`\mu_\mathrm i` (resp. :math:`\mu_\mathrm m`) denotes the shear modulus of the inclusion (resp. the matrix); :math:`\nu_\mathrm i` (resp. :math:`\nu_\mathrm m`) denotes the Poisson ratio of the inclusion (resp. the matrix).

The effective properties of this periodic microstructure are derived from the solution to the so-called *corrector* problem

.. math::
   :nowrap:
   :label: corrector_problem

   \begin{gather}
      \nabla\cdot\boldsymbol\sigma=\boldsymbol 0,\\
      \boldsymbol\sigma=\mathbf C:\boldsymbol\varepsilon,\\
      \boldsymbol\varepsilon=\mathbf E+\nabla^\mathrm{s}\mathbf u,
   \end{gather}

where :math:`\mathbf u` denotes the unknown, periodic displacement, :math:`\boldsymbol\varepsilon` (resp. :math:`\boldsymbol\sigma`) is the local strain (resp. stress) and :math:`\mathbf C` is the local stiffness (inclusion or matrix). From the solution to the above problem, the effective stiffness :math:`\mathbf C^\mathrm{eff}` is defined as the tensor mapping the macroscopic (imposed) strain :math:`\mathbf E=\langle\boldsymbol\varepsilon\rangle` to the macroscopic stress :math:`\boldsymbol\sigma=\langle\boldsymbol\sigma\rangle` (where quantities between angle brackets denote volume averages)

.. math::

   \mathbf C^\mathrm{eff}:\mathbf E=\frac1{L^d}\int_{\left(0,L\right)^d}\boldsymbol\sigma(x_1,x_2)\,\operatorname{d}\!x_1\cdots\operatorname{d}\!x_d.

.. note::
   This example is illustrated in two dimensions (:math:`d=2`). However, it is implemented so as to be dimension independent, so that :math:`d=3` should work out of the box.

In the present tutorial, we shall concentrate on the 1212 component of the effective stiffness, that is to say that the following macroscopic strain will be imposed

.. math::
   :label: macroscopic_strain

   \mathbf E=E_{12}\left(\mathbf e_1\otimes\mathbf e_2+\mathbf e_2\otimes\mathbf e_1\right),

and the volume average :math:`\langle\sigma_{12}\rangle` will be evaluated. To do so, the boundary value problem :eq:`corrector_problem` is transformed into an integral equation, known as the Lippmann--Schwinger equation (:ref:`Korringa, 1973 <KORR1973>`; :ref:`Zeller & Dederichs, 1973 <ZELL1973>` ; :ref:`Kröner, 1974 <KRON1974>`) . This equation reads

.. math::
   :label: Lippmann-Schwinger

   \boldsymbol\varepsilon+\boldsymbol\Gamma_0[\left(\mathbf C-\mathbf C_0\right):\boldsymbol\varepsilon]=\mathbf E,

where :math:`\mathbf C_0` denotes the stiffness of the reference material, :math:`\boldsymbol\Gamma_0` the related Green operator for strains, and :math:`\boldsymbol\varepsilon` the local strain tensor. We will assume that the reference material is isotropic, with shear modulus :math:`\mu_0` and Poisson ratio :math:`\nu_0`.

Following :ref:`Moulinec and Suquet (1998) <MOUL1998>`, the above Lippmann--Schwinger equation :eq:`Lippmann-Schwinger` is solved by means of fixed point iterations

.. math::
   :label: basic_scheme

   \boldsymbol\varepsilon^{k+1}=\mathbf E-\boldsymbol\Gamma_0[\left(\mathbf C-\mathbf C_0\right):\boldsymbol\varepsilon^k].

Finally, the above iterative scheme is discretized over a regular grid, leading to the basic uniform grid, periodic Lippmann--Schwinger solver.

Implementation of the Lippmann--Schwinger operator
==================================================

We will call the operator

.. math::
   \boldsymbol\varepsilon\mapsto\mathbf E-\boldsymbol\Gamma_0\left[\left(\mathbf C-\mathbf C_0\right):\boldsymbol\varepsilon\right]

the *Lippmann--Schwinger operator*. In the present section, we show how this operator is implemented as a class with Janus. This will be done by composing two successive operators, namely (i) the local operator

.. math::
   :label: local_operator

   \boldsymbol\varepsilon\mapsto\boldsymbol\tau=\left(\mathbf C-\mathbf C_0\right):\boldsymbol\varepsilon,

where :math:`\boldsymbol\tau` denotes the stress-polarization, and (ii) the Green operator for strains

.. math::
   :label: non-local_operator

   \boldsymbol\tau\mapsto\boldsymbol\Gamma_0[\boldsymbol\tau].

For the implementation of the local operator defined by Eq. :eq:`local_operator`, it is first observed that :math:`\mathbf C_0`, :math:`\mathbf C_\mathrm{i}` and :math:`\mathbf C_\mathrm{m}` being isotropic materials, :math:`\mathbf C-\mathbf C_0` is an isotropic tensor at any point of the unit-cell. In other words, both :math:`\mathbf C_\mathrm i-\mathbf C_0` and :math:`\mathbf C_\mathrm m-\mathbf C_0` will be defined as instances of :class:`FourthRankIsotropicTensor <janus.operators.FourthRankIsotropicTensor>`.

Furthermore, this operator is *local*. In other words, the output value in cell ``(i0, i1)`` depends on the input value in the same cell only (the neighboring cells are ignored). More precisely, we assume that a uniform grid of shape ``(n, n)`` is used to discretized Eq. :eq:`basic_scheme`. Then the material properties are constant in each cell, and we define ``delta_C[i0, i1, :, :]`` the matrix representation of :math:`\mathbf C-\mathbf C_0` (see :ref:`Mandel_notation`). Likewise, ``eps[i0, i1, :]`` is the vector representation of the strain tensor in cell ``(i0, i1)``. Then, the stress-polarization :math:`\left(\mathbf C-\mathbf C_0\right):\boldsymbol\varepsilon` in cell ``(i0, i1)`` is given by the expression::

    tau[i0, i1] = delta_C[i0, i1] @ eps[i0, i1],

where ``@`` denotes the matrix multiplication operator. It results from the above relation that the lcoal operator defined by :eq:`local_operator` should be implemented as a :class:`BlockDiagonalOperator2D <janus.operators.BlockDiagonalOperator2D>`. As for the non-local operator, it is instanciated by a simple call to the ``green_operator`` method of the relevant material (see :ref:`materials`).

The script starts with imports from the standard library, the SciPy stack and Janus itself:

.. literalinclude:: square_basic.py
   :start-after: Begin: imports
   :end-before: End: imports

We then define a class ``Example``, which represents the microsctructure described above. The first few lines of its initializer are pretty simple

.. literalinclude:: square_basic.py
   :start-after: Begin: init
   :end-before: End: init

``mat_i`` (resp. ``mat_m``, ``mat_0``) are the material properties of the inclusion (resp. the matrix, the reference material); ``n`` is the number of grid cells along each side, ``a`` is the size of the inclusion, and ``dim`` is the dimension of the physical space. The ``shape`` of the grid is stored in a tuple, the length of which depends on ``dim``.

.. note::
   As much as possible, keep your code dimension-independent. This means that the spatial dimension (2 or 3) should not be hard-coded. Rather, you should make it a rule to always parameterize the spatial dimension (use a variable ``dim``), even if you do not really intend to change this dimension. Janus object sometimes have different implementations depending on the spatial dimension. For example, the abstract class :class:`FourthRankIsotropicTensor <janus.operators.FourthRankIsotropicTensor>` has two concrete daughter classes :class:`FourthRankIsotropicTensor2D <janus.operators.FourthRankIsotropicTensor2D>` and :class:`FourthRankIsotropicTensor3D <janus.operators.FourthRankIsotropicTensor3D>`. However, both can be instantiated through the unique function :func:`isotropic_4 <janus.operators.isotropic_4>`, where the spatial dimension can be specified.

We then define the local operators :math:`\mathbf C_\mathrm i-\mathbf C_0` and :math:`\mathbf C_\mathrm m-\mathbf C_0` as :class:`FourthRankIsotropicTensor <janus.operators.FourthRankIsotropicTensor>`. It is recalled that the stiffness :math:`\mathbf C` of a material with bulk modulus :math:`\kappa` and shear modulus :math:`\mu` reads

.. math::
   \mathbf C = d\kappa\mathbf J+2\mu\mathbf K,

where :math:`d` denotes the dimension of the physical space and :math:`\mathbf J` (resp. :math:`\mathbf K`) denote the spherical (resp. deviatoric) projector tensor. In other words, the spherical and deviatoric projections of :math:`\mathbf C` are :math:`d\kappa` and :math:`2\mu`, respectively. As a consequence, the spherical and deviatoric projections of :math:`\mathbf C-\mathbf C_0` are :math:`d\left(\kappa-\kappa_0\right)` and :math:`2\left(\mu-\mu_0\right)`, respectively. This leads to the following definitions

.. literalinclude:: square_basic.py
   :start-after: Begin: create (C_i - C_0) and (C_m - C_0)
   :end-before: End: create (C_i - C_0) and (C_m - C_0)

Now, ``delta_C_i`` and ``delta_C_m`` are used to create the operator :math:`\boldsymbol\varepsilon\mapsto\left(\mathbf C-\mathbf C_0\right):\boldsymbol\varepsilon` as a :class:`BlockDiagonalOperator2D <janus.operators.BlockDiagonalOperator2D>`. Block-diagonal operators are initialized from an array of local operators, called ``ops`` below

.. todo::
   This code snippet is not dimension independent.

.. literalinclude:: square_basic.py
   :start-after: Begin: create local operator ε ↦ (C-C_0):ε
   :end-before: End: create local operator ε ↦ (C-C_0):ε

The upper-left quarter of the unit-cell is filled with ``delta_C_i`` (:math:`\mathbf C_\mathrm i-\mathbf C_0`), while the remainder of the unit-cell receives ``delta_C_m`` (:math:`\mathbf C_\mathrm m-\mathbf C_0`). Finally, a :class:`BlockDiagonalOperator2D <janus.operators.BlockDiagonalOperator2D>` is created from the array of local operators. It is called ``eps_to_tau`` as it maps the strain (:math:`\boldsymbol\varepsilon`) to the stress-polarization (:math:`\boldsymbol\tau`).

.. note::
   ``eps_to_tau`` is not a *method*. Rather, it is an *attribute*, which turns out to be a function.

Finally, the discrete Green operator for strains associated with the reference material :math:`\mathbf C_0` is created. This requires first to create a FFT object (see :ref:`FFT`).

.. todo::
   Document Green operators for strains.

.. literalinclude:: square_basic.py
   :start-after: Begin: create non-local operator ε ↦ Γ_0[ε]
   :end-before: End: create non-local operator ε ↦ Γ_0[ε]

The Lippmann--Schwinger operator :math:`\boldsymbol\varepsilon\mapsto\boldsymbol\Gamma_0[\left(\mathbf C-\mathbf C_0\right):\boldsymbol\varepsilon]` is then defined by composition

.. literalinclude:: square_basic.py
   :start-after: Begin: apply
   :end-before: End: apply

which closes the definition of the class ``Example``.

.. note::
   Note how we allowed for the output array to be passed by reference, thus allowing for memory reuse.

The main block of the script
============================

It starts with the definition of a few parameters

.. literalinclude:: square_basic.py
   :start-after: Begin: params
   :end-before: End: params

Then, an instance of class ``Example`` is created

.. literalinclude:: square_basic.py
   :start-after: Begin: instantiate example
   :end-before: End: instantiate example

We then define ``eps_macro``, which stores the imposed value of the macroscopic strain :math:`\mathbf E`, and ``eps`` and ``eps_new``, which hold two successive iterates of the local strain field :math:`\boldsymbol\varepsilon`.

.. literalinclude:: square_basic.py
   :start-after: Begin: define strains
   :end-before: End: define strains

.. note::
   The shape of the arrays ``eps`` and ``eps_new`` is simply inferred from the shape of the input of the Green operator for strains :math:`\boldsymbol\Gamma_0`.

We will not implement a stopping criterion for this simple example. Rather, a fixed number of iterations will be specified. Meanwhile, the residual

.. math::
   :label: residual

   \left(\frac1{L^d}\int_{(0,L)^d}\left(\boldsymbol\varepsilon^{k+1}-\boldsymbol\varepsilon^k\right):\left(\boldsymbol\varepsilon^{k+1}-\boldsymbol\varepsilon^k\right)\operatorname{d}\!x_1\cdots\operatorname{d}\!x_d\right)^{1/2},

will be computed and stored at each iteration through the following estimate

.. code-block:: python

   norm(new_eps-eps)/sqrt(num_cells)/norm(avg_eps),

where normalization (using :math:`\lVert\mathbf E\rVert`) is also applied.

.. note::
   Note that the quantity defined by Eq. :eq:`residual` is truly a residual. Indeed, it is the norm of the difference between the left- and right-hand side in Eq. :eq:`Lippmann-Schwinger`, since :math:`\boldsymbol\varepsilon^{k+1}-\boldsymbol\varepsilon^k=\mathbf E-\boldsymbol\Gamma_0[\left(\mathbf C-\mathbf C_0\right):\boldsymbol\varepsilon^k]-\boldsymbol\varepsilon^k`.

The fixed-point iterations defined by Eq. :eq:`basic_scheme` are then implemented as follows

.. literalinclude:: square_basic.py
   :start-after: Begin: iterate
   :end-before: End: iterate

and the results are post-processed

.. literalinclude:: square_basic.py
   :start-after: Begin: post-process
   :end-before: End: post-process

To compute the macroscopic stiffness, we recall the definition of the stress-polarization from which we find

.. math::
   \mathbf C^\mathrm{eff}:\mathbf E=\langle\boldsymbol\sigma\rangle=\langle\mathbf C:\boldsymbol\varepsilon+\boldsymbol\tau\rangle=\mathbf C:\mathbf E+\langle\boldsymbol\tau\rangle.

Then, from the specific macroscopic strain :math:`\mathbf E` that we considered [see Eq. :eq:`macroscopic_strain`]

.. math::

   C_{1212}^\mathrm{eff}=C_{0, 1212}+\frac{\langle\tau_{12}\rangle}{2E_{12}}=C_{0, 1212}+\frac{[\langle\boldsymbol\tau\rangle]_{-1}}{2[\mathbf E]_{-1}}=\mu_0+\frac{[\langle\boldsymbol\tau\rangle]_{-1}}{2[\mathbf E]_{-1}}

where brackets refer to the :ref:`Mandel_notation`, and the -1 index denotes the last component of the column-vector (which, in Mandel's notation, refers to the 12 component of second-rank symmetric tensors, both in two and three dimensions). We get the following approximation

.. code-block:: none

   C_1212 # 1.41903971282,

and the map of the local strains is shown in :numref:`fig_strains`, while :numref:`fig_residual` shows that the residual decreases (albeit slowly) with the number of iterations. This completes this tutorial.

.. _fig_strains:
.. figure:: eps.*
   :align: center

   The maps of :math:`\boldsymbol\varepsilon_{11}` (left), :math:`\boldsymbol\varepsilon_{22}` (middle) and :math:`\boldsymbol\varepsilon_{12}` (right). Different color scales were used for the left and middle map, and for the right map. Note that in the above representation, the :math:`x_1` axis points to the bottom, while the :math:`x_2` axis points to the right.

.. _fig_residual:
.. figure:: residual.*
   :align: center

   The normalized residual as a function of the number of iterations.

The complete program
====================

The complete program can be downloaded :download:`here <./square_basic.py>`.

.. literalinclude:: square_basic.py
