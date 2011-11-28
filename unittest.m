clear

rand('seed', 1);
randn('seed', 1);

L = 32^2 * 3;

M = L;
Mrows = 32;
K = 2;

Lsz = sqrt(L);

display_every = 20;
display_every = 10;
save_every = 10;

lambda = 1.0;

buff = 4;

datasource = 'movies';
datasource = 'images';

datasource = 'tiny';

switch datasource
    case 'tiny'
        tiny_idx = 1;                   % data position index
        tiny_idx = 2000000;             % data position index
        tiny_size = 79302017;           % tiny images max idx
        Lsz = 32;                       % dummy variable

    otherwise
        Lsz = sqrt(L);
end


Btest = 100;

mintype_inf = 'minFunc_sparsenorm';
mintype_lrn = 'gd_sparsenorm';

tol_inf = 0.001;
tol_inf = 0.01;

warning('off', 'MATLAB:nearlySingularMatrix');

test_every = 100;

paramstr = sprintf('L=%03d_M=%03d_%s',L,M,datestr(now,30));


reinit

eta_log = [];
objtest_log = [];



eta = 0.01;
target_angle = 0.1;


num_trials = 10000;
%B = 10;
%sparsenet

B = 40;
sparsenet

B = 50;
sparsenet


