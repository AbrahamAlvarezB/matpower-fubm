function [dSbus_dPxsh] = dSbus_dsh(branch, V, side, vcart)
%DSBUS_DSH   Computes partial derivatives of power injection w.r.t. Theta_shift.
%
%   Theta_shift can be used either to control the Pf or Pt to a certain set 
%   value Pfset or Ptset respectively for active power control. Thus, the 
%   derivatives are separated for each function. The derivatives w.r.t. 
%   Theta_shift will be chosen for either Pf or Pt control, depending on 
%   the 3rd argument "side".
%   So that:
%
%   side = 1 : Pf = Pfset, "from side", Phase Shifter Transformers and VSC
%   side = 2 : Pt = Ptset, "to side", 
%
%   The derivatives will be taken with respect to polar or cartesian coordinates
%   of voltage, depending on the 4th argument. So far only polar
%
%   [DSBUS_DPFSH] = DSBUS_DSH(BRANCH, V, 1, 0)
%
%   FROM SIDE
%   Returns one matrix containing partial derivatives of the complex bus
%   power injections w.r.t Theta_shift, respectively (for all buses).
%
%   [DSBUS_DPTSH] = DSBUS_DSH(BRANCH, V, 2, 0)
%
%   TO SIDE
%   Returns one matrix containing partial derivatives of the complex bus
%   power injections w.r.t Theta_shift, respectively (for all buses).
%
%   The following explains the expressions used to form the matrices:
%
%   S = diag(V) * conj(Ibus) = diag(conj(Ibus)) * V
%   S = diag(V) * conj(Ybus * V)
%   where:
%       Ybus = Cf' * Yf + Ct' * Yt + diag(Ysh)
%
%       Yf = Yff * Cf + Yft * Ct
%       Yt = Ytf * Cf + Ytt * Ct
%
%       Ytt = Ys + 1j*Bc/2
%       Yff = Gsw+( (Ytt+1j*Beq) ./ ((k2.^2).*tap .* conj(tap))  ) %%<<AAB- FUBM formulation- Original: Yff = Ytt ./ (tap .* conj(tap));
%       Yft = - Ys ./ conj(tap)
%       Ytf = - Ys ./ tap 
%
%   Polar coordinates:
%     Partials of Ytt, Yff, Yft and Ytf w.r.t. Theta_shift
%       dYtt/dsh = zeros(nl,1)
%       dYff/dsh = zeros(nl,1)
%       dYft/dsh = -Ys./(-1j*k2.*conj(tap))
%       dYtf/dsh = -Ys./( 1j*k2.*tap      )
%
%     Partials of Yf, Yt, Ybus w.r.t. Theta_shift
%       dYf/dsh = dYff/dsh * Cf + dYft/dsh * Ct
%       dYt/dsh = dYtf/dsh * Cf + dYtt/dsh * Ct
%
%       dYbus/dsh = Cf' * dYf/dsh + Ct' * dYt/dsh    
%
%     Partials of Sbus w.r.t. shift angle
%       dSbus/dsh = diag(V) * conj(dYbus/dsh * V)
%
%   Examples:
%       [dSbus_dPfsh] = dSbus_dsh(branch, V, 1);
%       [dSbus_dPfsh] = dSbus_dsh(branch, V, 1, vcart);
%       [dSbus_dPtsh] = dSbus_dsh(branch, V, 2);
%       [dSbus_dPtsh] = dSbus_dsh(branch, V, 2, vcart);
%
%
%   For more details on the derivations behind the derivative code used
%   in MATPOWER information, see:
%
%   [TN2]  R. D. Zimmerman, "AC Power Flows, Generalized OPF Costs and
%          their Derivatives using Complex Matrix Notation", MATPOWER
%          Technical Note 2, February 2010.
%             http://www.pserc.cornell.edu/matpower/TN2-OPF-Derivatives.pdf
%   [TN4]  B. Sereeter and R. D. Zimmerman, "AC Power Flows and their
%          Derivatives using Complex Matrix Notation and Cartesian
%          Coordinate Voltages," MATPOWER Technical Note 4, April 2018.
%             http://www.pserc.cornell.edu/matpower/
%                                           TN4-OPF-Derivatives-Cartesian.pdf
%   [TNX]  A. Alvarez-Bustos, "AC/DC FUBM and their Derivatives using FUBM
%          Complex Matrix Notation" MATPOWER Technical Note x, Month 20XX.
%             http://www.pserc.cornell.edu/matpower/
%                                           TNX-OPF-Derivatives-FUBM.pdf   %%AAB- Technical note to be written
                                           
%   ABRAHAM ALVAREZ BUSTOS
%   This code is based and created for MATPOWER
%   This is part of the Flexible Universal Branch Model (FUBM) for Matpower
%   For more info about the model, email: 
%   snoop_and@hotmail.com, abraham.alvarez-bustos@durham.ac.uk 

%   MATPOWER
%   Copyright (c) 1996-2018, Power Systems Engineering Research Center (PSERC)
%   by Ray Zimmerman, PSERC Cornell
%   and Baljinnyam Sereeter, Delft University of Technology
%
%   This file is part of MATPOWER.
%   Covered by the 3-clause BSD License (see LICENSE file for details).
%   See http://www.pserc.cornell.edu/matpower/ for more info.

[F_BUS, T_BUS, BR_R, BR_X, BR_B, RATE_A, RATE_B, ...
    RATE_C, TAP, SHIFT, BR_STATUS, PF, QF, PT, QT, MU_SF, MU_ST, ...
    ANGMIN, ANGMAX, MU_ANGMIN, MU_ANGMAX, VF_SET, VT_SET,TAP_MAX, ...
    TAP_MIN, CONV, BEQ, K2, BEQ_MIN, BEQ_MAX, SH_MIN, SH_MAX, GSW, ...
    ALPH1, ALPH2, ALPH3] = idx_brch;%<<AAB-extra fields for FUBM

%% default input args
if nargin < 4
    vcart = 0;      %% default to polar coordinates
end

%% selection of Side
if side == 1    %from side
    iPxsh = find (branch(:,PF)~=0 & branch(:, BR_STATUS)==1 & (branch(:, SH_MIN)~=-360 | branch(:, SH_MAX)~=360)); %AAB- Find branch locations of Pf control size[nPfsh,1]
elseif side ==2 %to side
    iPxsh = find (branch(:,PT)~=0 & branch(:, BR_STATUS)==1 & (branch(:, SH_MIN)~=-360 | branch(:, SH_MAX)~=360)); %AAB- Find branch locations of Pf control size[nPtsh,1]
else
    error('dSbus_dsh: Side for element active power control can only be type 1 (from side) or 2 (to side)')    
end  
%% constants
nb = length(V);             %% number of buses
nl = size(branch, 1);       %% number of lines
nPxsh = length(iPxsh);      %% AAB- Number of elements with active power flow controlled by theta_sh  

[stat, Cf, Ct, k2, tap, Ys] = getbranchdata(branch, nb); %AAB- Gets the requested data from branch

if vcart
    error('dSbus_dsh: Derivatives of Power balance equations w.r.t Theta_shift in cartasian have not been coded yet')    

else %AAB- Polar Version
    diagV = sparse(1:nb, 1:nb, V, nb, nb); %AAB- diagV = sparse(diag(V))
    
    %Selector of active Theta shifters 
    shAux = zeros(nl,1);%AAB- Vector of zeros for the seclector
    shAux(iPxsh) = 1; %AAB- Fill the selector with "1" where Theta_shift is active
    diagYssh = sparse( diag(shAux.*Ys) ); %AAB- Theta_shift selector multilied by the series addmitance Ys, size [nl,nl]
    
    %Dimensionalize (Allocate for computational speed)
    dYtt_dsh = sparse( zeros(nl,nPxsh) );
    dYff_dsh = sparse( zeros(nl,nPxsh) );
    dYft_dsh = sparse( zeros(nl,nPxsh) );
    dYtf_dsh = sparse( zeros(nl,nPxsh) );
    dSbus_dPxsh = sparse( zeros(nb,nPxsh) );
    
    for k=1:nPxsh
        Yssh=diagYssh(:,iPxsh(k)); %AAB- Selects the column of diagYssh representing only the active shift angles
        
        %Partials of Ytt, Yff, Yft and Ytf w.r.t. Theta shift
        dYtt_dsh(:, k) = sparse( zeros(nl,1) );
        dYff_dsh(:, k) = sparse( zeros(nl,1) );
        dYft_dsh(:, k) = sparse( -Yssh./(-1j*k2.*conj(tap)) ); %AAB- It also could be: sparse( ( -1j .* Yssh ) ./ ( k2 .* conj(tap) ) );
        dYtf_dsh(:, k) = sparse( -Yssh./( 1j*k2.*tap      ) ); %AAB- It also could be: sparse( (  1j .* Yssh ) ./ ( k2 .*      tap  ) );

        %Partials of Yf, Yt, Ybus w.r.t. Theta shift
        dYf_dsh = dYff_dsh(:, k).* Cf + dYft_dsh(:, k).* Ct; %AAB- size [nl,nb] per active Theta shift
        dYt_dsh = dYtf_dsh(:, k).* Cf + dYtt_dsh(:, k).* Ct; %AAB- size [nl,nb] per active Theta shift

        dYbus_dsh = Cf' * dYf_dsh + Ct' * dYt_dsh;     %AAB- size [nb,nb] per active Theta shift    

        %Partials of S w.r.t. Theta shift
        dSbus_dPxsh(:, k) = diagV * conj(dYbus_dsh * V); %AAB- Final dSbus_dsh has a size of [nb, nPxsh] 
    end
    
end