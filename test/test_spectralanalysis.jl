using Test
using QuantumOptics

mutable struct SpectralanalysisTestOperator <: Operator end

@testset "spectralanalysis" begin

srand(0)

sprandop(b) = sparse(DenseOperator(b, rand(Complex128, length(b), length(b))))

# Test diagonalization
@test_throws ArgumentError eigenstates(SpectralanalysisTestOperator())
@test_throws bases.IncompatibleBases eigenstates(DenseOperator(GenericBasis(3), GenericBasis(4)))
@test_throws ArgumentError eigenenergies(SpectralanalysisTestOperator())
@test_throws bases.IncompatibleBases eigenenergies(DenseOperator(GenericBasis(3), GenericBasis(4)))


# Test hermitian diagonalization
b = GenericBasis(5)
a = randoperator(b)
H = (a+dagger(a))/2
U = expm(1im*H)
d = [-3, -2.6, -0.1, 0.0, 0.6]
D = DenseOperator(b, diagm(d))
Dsp = sparse(D)
@test eigenenergies(D) ≈ d
@test eigenenergies(Dsp, 3, info=false) ≈ d[1:3]

R = U*D*dagger(U)
Rsp = sparse(R)
@test eigenenergies((R+dagger(R))/2) ≈ d
@test eigenenergies((Rsp+dagger(Rsp))/2, 3; info=false) ≈ d[1:3]

E, states = eigenstates((R+dagger(R))/2, 3)
Esp, states_sp = eigenstates((Rsp+dagger(Rsp))/2, 3, info=false)
for i=1:3
    @test E[i] ≈ d[i]
    @test Esp[i] ≈ d[i]
    v = U.data[1,i]/states[i].data[1]
    @test states[i].data*v ≈ U.data[:,i]
    v = U.data[1,i]/states_sp[i].data[1]
    @test states_sp[i].data*v ≈ U.data[:,i]
end


# Test nonhermitian diagonalization
b = GenericBasis(5)
a = randoperator(b)
H = (a+dagger(a))/2
U = expm(1im*H)
d = [-3+0.2im, -2.6-0.1im, -0.1+0.5im, 0.0, 0.6+0.3im]
D = DenseOperator(b, diagm(d))
Dsp = sparse(D)
@test eigenenergies(D; warning=false) ≈ d
@test eigenenergies(Dsp, 3; warning=false, info=false) ≈ d[1:3]

R = U*D*dagger(U)
Rsp = sparse(R)
@test eigenenergies(R; warning=false) ≈ d
@test eigenenergies(Rsp, 3; warning=false, info=false) ≈ d[1:3]

E, states = eigenstates(R, 3; warning=false)
Esp, states_sp = eigenstates(Rsp, 3; warning=false, info=false)
for i=1:3
    @test E[i] ≈ d[i]
    @test Esp[i] ≈ d[i]
    v = U.data[1,i]/states[i].data[1]
    @test states[i].data*v ≈ U.data[:,i]
    v = U.data[1,i]/states_sp[i].data[1]
    @test states_sp[i].data*v ≈ U.data[:,i]
end


# Test simdiag
spinbasis = SpinBasis(1//2)
sx = sigmax(spinbasis)
sy = sigmay(spinbasis)
sz = sigmaz(spinbasis)
twospinbasis = spinbasis ⊗ spinbasis
Sx = full(sum([embed(twospinbasis, i, sx) for i=1:2]))/2.
Sy = full(sum([embed(twospinbasis, i, sy) for i=1:2]))/2.
Sz = full(sum([embed(twospinbasis, i, sz) for i=1:2]))/2.
Ssq = Sx^2 + Sy^2 + Sz^2
d, v = simdiag([Sz, Ssq])
@test d[1] == [-1.0, 0, 0, 1.0]
@test d[2] ≈ [2, 0.0, 2, 2]
@test_throws ErrorException simdiag([Sx, Sy])

threespinbasis = spinbasis ⊗ spinbasis ⊗ spinbasis
Sx3 = full(sum([embed(threespinbasis, i, sx) for i=1:3])/2.)
Sy3 = full(sum([embed(threespinbasis, i, sy) for i=1:3])/2.)
Sz3 = full(sum([embed(threespinbasis, i, sz) for i=1:3])/2.)
Ssq3 = Sx3^2 + Sy3^2 + Sz3^2
d3, v3 = simdiag([Ssq3, Sz3])
dsq3_std = eigenenergies(full(Ssq3))
@test diagm(dsq3_std) ≈ v3'*Ssq3.data*v3

fockbasis = FockBasis(4)
@test_throws ErrorException simdiag([Sy3, Sz3])
@test_throws ErrorException simdiag([full(destroy(fockbasis)), full(create(fockbasis))])

end # testset
