
clear

randn('seed', 1);
rand('seed', 1);

K = 2;

Lsz = 4;
L = Lsz^2;
Msz = 2;
M = Msz^2;

batch_size = 10;

A = randn(L, M);
s = randn(M, batch_size);
X = randn(L, batch_size);

lambda = 10;

tic
checkgrad('objfun_s_sparsenorm', s(:), 1e-5, A, X, lambda, K);
toc

