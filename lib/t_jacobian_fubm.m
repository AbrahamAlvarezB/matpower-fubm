function t_jacobian_fubm(quiet)
%T_JACOBIAN_FUBM  Numerical tests of partial derivative code.

%   This code compares the results from the obtained derivatives against
%   the aproximated derivatives using the finite differences method.

%   FINITE DIFFERENCES METHOD
%   This method calculates the derivatives with an aproximation as:
%   f'(x) ~~ ( f(x+h) - f(x) ) / h 

%   ABRAHAM ALVAREZ BUSTOS
%   This code is based and created for MATPOWER
%   This is part of the Flexible Universal Branch Model (FUBM) for Matpower
%   For more info about the model, email: 
%   snoop_and@hotmail.com, abraham.alvarez-bustos@durham.ac.uk 
%
%   MATPOWER
%   Copyright (c) 2004-2016, Power Systems Engineering Research Center (PSERC)
%   by Ray Zimmerman, PSERC Cornell
%   and Baljinnyam Sereeter, Delft University of Technology
%
%   This file is part of MATPOWER.
%   Covered by the 3-clause BSD License (see LICENSE file for details).
%   See https://matpower.org for more info.

if nargin < 1
    quiet = 0;
end

t_begin(64, quiet); %AAB-initializes the global test counters

casefile = 'fubm_case_30_2MTDC_ctrls_vt1_pf';

%% define named indices into bus, gen, branch matrices
[PQ, PV, REF, NONE, BUS_I, BUS_TYPE, PD, QD, GS, BS, BUS_AREA, VM, ...
    VA, BASE_KV, ZONE, VMAX, VMIN, LAM_P, LAM_Q, MU_VMAX, MU_VMIN] = idx_bus;
[F_BUS, T_BUS, BR_R, BR_X, BR_B, RATE_A, RATE_B, ...
    RATE_C, TAP, SHIFT, BR_STATUS, PF, QF, PT, QT, MU_SF, MU_ST, ...
    ANGMIN, ANGMAX, MU_ANGMIN, MU_ANGMAX, VF_SET, VT_SET,TAP_MAX, ...
    TAP_MIN, CONV, BEQ, K2, BEQ_MIN, BEQ_MAX, SH_MIN, SH_MAX, GSW, ...
    ALPH1, ALPH2, ALPH3] = idx_brch;%<<AAB-extra fields for FUBM- Original: idx_brch

%% run powerflow to get solved case
mpopt = mpoption('verbose', 0, 'out.all', 0);
mpc = loadcase(casefile);
[baseMVA, bus, gen, branch, success, et] = runpf(mpc, mpopt);

%% switch to internal bus numbering and build admittance matrices
[i2e, bus, gen, branch] = ext2int(bus, gen, branch);
[Ybus, Yf, Yt] = makeYbus(baseMVA, bus, branch);
Sbus = makeSbus(baseMVA, bus, gen);  %% net injected power in p.u.  Sbus = Sbusg - Sbusd;
Ybus_full   = full(Ybus);
Yf_full     = full(Yf);
Yt_full     = full(Yt);
Vm = bus(:, VM);
Va = bus(:, VA) * pi/180;
V = Vm .* exp(1j * Va);
Vr = real(V);
Vi = imag(V);
f = branch(:, F_BUS);       %% list of "from" buses
t = branch(:, T_BUS);       %% list of "to" buses
nl = length(f);
nb = length(V);             %                                            [1,2,...,nb]
VV = V * ones(1, nb);       %% Voltages are repeated in each column VV = [V,V,..., V]; size [nb,nb]
SS = Sbus * ones(1, nb);    %% Sbus      is repeated in each column SS = [Sbus,Sbus,...,Sbus]; size [nb,nb] where: Sbus = Sbusg - Sbusd; 
pert = 1e-8;                %% perturbation factor (h) for the Finite Differences Method


%%-----  run tests for polar coordinates -----
        coord = 'polar';
        vv = {'a', 'm'}; %a for angle, m for magnitude
        V1p = (Vm*ones(1,nb)) .* (exp(1j * (Va*ones(1,nb) + pert*eye(nb,nb)))); %Perturbed V for Va+pert
        V2p = (Vm*ones(1,nb) + pert*eye(nb,nb)) .* (exp(1j * Va) * ones(1,nb)); %Perturbed V for Vm+pert

    %% -----  check dSbus_dx code  -----
    %%sparse matrices derivatives
    [dSbus_dV1, dSbus_dV2, dSbus_dPfsh, dSbus_dQfma,dSbus_dBeqz,...
        dSbus_dBeqv, dSbus_dVtma, dSbus_dQtma] = dSbus_dx(Ybus, branch, V, 0);
    dSbus_dV1_sp   = full(dSbus_dV1);
    dSbus_dV2_sp   = full(dSbus_dV2);
    dSbus_dPfsh_sp = full(dSbus_dPfsh);
    dSbus_dQfma_sp = full(dSbus_dQfma);
    dSbus_dBeqz_sp = full(dSbus_dBeqz);
    dSbus_dBeqv_sp = full(dSbus_dBeqv);
    dSbus_dVtma_sp = full(dSbus_dVtma);
    dSbus_dQtma_sp = full(dSbus_dQtma);
    %% compute numerically to compare (Finite Differences Method)
    %Voltages
    num_dSbus_dV1 = full( (V1p .* conj(Ybus * V1p) - VV .* conj(Ybus * VV)) / pert );
    num_dSbus_dV2 = full( (V2p .* conj(Ybus * V2p) - VV .* conj(Ybus * VV)) / pert );
    %FUBM extra variables
    [num_dSbus_dPfsh, num_dSbus_dQfma,num_dSbus_dBeqz,...
        num_dSbus_dBeqv, num_dSbus_dVtma, num_dSbus_dQtma] = dSbus_dxPert(baseMVA, bus, branch, V, pert, 0); %Size of each derivatives [nb, nXXxx]
    
    num_dSbus_dPfsh_sp = full(num_dSbus_dPfsh);
    num_dSbus_dQfma_sp = full(num_dSbus_dQfma);
    num_dSbus_dBeqz_sp = full(num_dSbus_dBeqz);
    num_dSbus_dBeqv_sp = full(num_dSbus_dBeqv);
    num_dSbus_dVtma_sp = full(num_dSbus_dVtma);
    num_dSbus_dQtma_sp = full(num_dSbus_dQtma);
    
    t_is(dSbus_dV1_sp, num_dSbus_dV1, 5, sprintf('%s - dSbus_dV%s (sparse)', coord, vv{1}));
    t_is(dSbus_dV2_sp, num_dSbus_dV2, 5, sprintf('%s - dSbus_dV%s (sparse)', coord, vv{2}));
    
    t_is(dSbus_dPfsh_sp, num_dSbus_dPfsh_sp, 5, sprintf('%s - dSbus_dPfsh (sparse)', coord)); 
    t_is(dSbus_dQfma_sp, num_dSbus_dQfma_sp, 5, sprintf('%s - dSbus_dQfma (sparse)', coord));
    t_is(dSbus_dBeqz_sp, num_dSbus_dBeqz_sp, 5, sprintf('%s - dSbus_dBeqz (sparse)', coord));
    t_is(dSbus_dBeqv_sp, num_dSbus_dBeqv_sp, 5, sprintf('%s - dSbus_dBeqv (sparse)', coord));    
    t_is(dSbus_dVtma_sp, num_dSbus_dVtma_sp, 5, sprintf('%s - dSbus_dVtma (sparse)', coord)); 
    t_is(dSbus_dQtma_sp, num_dSbus_dQtma_sp, 5, sprintf('%s - dSbus_dQtma (sparse)', coord)); 
    
    %%-----  check dSbr_dV code  -----
    %% full matrices
    [dSf_dV1_full, dSf_dV2_full, dSt_dV1_full, dSt_dV2_full, Sf, St] = dSbr_dV(branch, Yf_full, Yt_full, V, vcart);

    %% sparse matrices
    [dSf_dV1, dSf_dV2, dSt_dV1, dSt_dV2, Sf, St] = dSbr_dV(branch, Yf, Yt, V, vcart);
    dSf_dV1_sp = full(dSf_dV1);
    dSf_dV2_sp = full(dSf_dV2);
    dSt_dV1_sp = full(dSt_dV1);
    dSt_dV2_sp = full(dSt_dV2);

    %% compute numerically to compare
    V1pf = V1p(f,:);
    V2pf = V2p(f,:);
    V1pt = V1p(t,:);
    V2pt = V2p(t,:);
    Sf2 = (V(f)*ones(1,nb)) .* conj(Yf * VV);
    St2 = (V(t)*ones(1,nb)) .* conj(Yt * VV);
    S1pf = V1pf .* conj(Yf * V1p);
    S2pf = V2pf .* conj(Yf * V2p);
    S1pt = V1pt .* conj(Yt * V1p);
    S2pt = V2pt .* conj(Yt * V2p);

    num_dSf_dV1 = full( (S1pf - Sf2) / pert );
    num_dSf_dV2 = full( (S2pf - Sf2) / pert );
    num_dSt_dV1 = full( (S1pt - St2) / pert );
    num_dSt_dV2 = full( (S2pt - St2) / pert );

    t_is(dSf_dV1_sp, num_dSf_dV1, 5, sprintf('%s - dSf_dV%s (sparse)', coord, vv{1}));
    t_is(dSf_dV2_sp, num_dSf_dV2, 5, sprintf('%s - dSf_dV%s (sparse)', coord, vv{2}));
    t_is(dSt_dV1_sp, num_dSt_dV1, 5, sprintf('%s - dSt_dV%s (sparse)', coord, vv{1}));
    t_is(dSt_dV2_sp, num_dSt_dV2, 5, sprintf('%s - dSt_dV%s (sparse)', coord, vv{2}));
    t_is(dSf_dV1_full, num_dSf_dV1, 5, sprintf('%s - dSf_dV%s (full)', coord, vv{1}));
    t_is(dSf_dV2_full, num_dSf_dV2, 5, sprintf('%s - dSf_dV%s (full)', coord, vv{2}));
    t_is(dSt_dV1_full, num_dSt_dV1, 5, sprintf('%s - dSt_dV%s (full)', coord, vv{1}));
    t_is(dSt_dV2_full, num_dSt_dV2, 5, sprintf('%s - dSt_dV%s (full)', coord, vv{2}));

    %%-----  check dAbr_dV code  -----
    %% full matrices
    [dAf_dV1_full, dAf_dV2_full, dAt_dV1_full, dAt_dV2_full] = ...
                            dAbr_dV(dSf_dV1_full, dSf_dV2_full, dSt_dV1_full, dSt_dV2_full, Sf, St);
    %% sparse matrices
    [dAf_dV1, dAf_dV2, dAt_dV1, dAt_dV2] = ...
                            dAbr_dV(dSf_dV1, dSf_dV2, dSt_dV1, dSt_dV2, Sf, St);
    dAf_dV1_sp = full(dAf_dV1);
    dAf_dV2_sp = full(dAf_dV2);
    dAt_dV1_sp = full(dAt_dV1);
    dAt_dV2_sp = full(dAt_dV2);

    %% compute numerically to compare
    num_dAf_dV1 = full( (abs(S1pf).^2 - abs(Sf2).^2) / pert );
    num_dAf_dV2 = full( (abs(S2pf).^2 - abs(Sf2).^2) / pert );
    num_dAt_dV1 = full( (abs(S1pt).^2 - abs(St2).^2) / pert );
    num_dAt_dV2 = full( (abs(S2pt).^2 - abs(St2).^2) / pert );

    t_is(dAf_dV1_sp, num_dAf_dV1, 4, sprintf('%s - dAf_dV%s (sparse)', coord, vv{1}));
    t_is(dAf_dV2_sp, num_dAf_dV2, 4, sprintf('%s - dAf_dV%s (sparse)', coord, vv{2}));
    t_is(dAt_dV1_sp, num_dAt_dV1, 4, sprintf('%s - dAt_dV%s (sparse)', coord, vv{1}));
    t_is(dAt_dV2_sp, num_dAt_dV2, 4, sprintf('%s - dAt_dV%s (sparse)', coord, vv{2}));
    t_is(dAf_dV1_full, num_dAf_dV1, 4, sprintf('%s - dAf_dV%s (full)', coord, vv{1}));
    t_is(dAf_dV2_full, num_dAf_dV2, 4, sprintf('%s - dAf_dV%s (full)', coord, vv{2}));
    t_is(dAt_dV1_full, num_dAt_dV1, 4, sprintf('%s - dAt_dV%s (full)', coord, vv{1}));
    t_is(dAt_dV2_full, num_dAt_dV2, 4, sprintf('%s - dAt_dV%s (full)', coord, vv{2}));
%end

t_end;
