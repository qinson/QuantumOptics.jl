using Base.Test
using QuantumOptics

srand(0)

# Set up operators
spinbasis = SpinBasis(1//2)

sx = sigmax(spinbasis)
sy = sigmay(spinbasis)
sz = sigmaz(spinbasis)

sx_dense = full(sx)
sy_dense = full(sy)
sz_dense = full(sz)

@test typeof(sx_dense) == DenseOperator
@test typeof(sparse(sx_dense)) == SparseOperator
@test sparse(sx_dense) == sx

b = FockBasis(3)
I = sparse_identityoperator(b)
I_dense = dense_identityoperator(b)

# Test tensor product
s = tensor(sx, sy, sz)
s_dense = tensor(sx_dense, sy_dense, sz_dense)

@test typeof(I) == SparseOperator
@test typeof(I_dense) == DenseOperator
@test_approx_eq 0. norm((I_dense-full(I)).data)
@test_approx_eq 0. norm((s_dense - full(s)).data)

@test I == identityoperator(destroy(b))

type A <: Operator
end

a = A()

@test_throws ArgumentError sparse(a)

@test diagonaloperator(b, [1, 1, 1, 1]) == I
@test diagonaloperator(b, [1., 1., 1., 1.]) == I
@test diagonaloperator(b, [1im, 1im, 1im, 1im]) == 1im*I
@test diagonaloperator(b, [0:3;]) == number(b)


# Test partial trace
b1 = NLevelBasis(3)
b2 = SpinBasis(1//2)
b3 = FockBasis(3)
b = b1 ⊗ b2 ⊗ b3

rho = DenseOperator(b, rand(Complex128, length(b), length(b)))
rho_sparse = sparse(rho)

x1 = ptrace(rho, [2,3])
x2 = ptrace(rho_sparse, [2,3])
@test_approx_eq_eps 0. tracedistance_general(x1, full(x2)) 1e-5

x1 = ptrace(rho, [1])
x2 = ptrace(rho_sparse, [1])
@test_approx_eq_eps 0. tracedistance_general(x1, full(x2)) 1e-5

x1 = ptrace(rho, [1,2,3])
x2 = ptrace(rho_sparse, [1,2,3])
@test_approx_eq_eps x1 x2 1e-5


# Test permutating systems
b1a = NLevelBasis(2)
b1b = SpinBasis(3//2)
b2a = SpinBasis(1//2)
b2b = FockBasis(7)
b3a = FockBasis(2)
b3b = NLevelBasis(4)

rho1 = SparseOperator(b1a, b1b, sparse(rand(Complex128, length(b1a), length(b1b))))
rho2 = SparseOperator(b2a, b2b, sparse(rand(Complex128, length(b2a), length(b2b))))
rho3 = SparseOperator(b3a, b3b, sparse(rand(Complex128, length(b3a), length(b3b))))

@test_approx_eq_eps 0. tracedistance_general(full(permutesystems(rho1⊗rho2⊗rho3, [2, 1, 3])), full(rho2⊗rho1⊗rho3)) 1e-5
