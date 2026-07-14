clear; clc; close all;

%% ====================================
% array parametes
m = 14; n = 14;
L = m*n;

d = 0.0074;                 % unit：m
freq = 18.7;              % GHz
c = 3e8;
lambda = c/(freq*1e9);

NA = 361;

%% ====================================
% scan angle
theta0 = 60*pi/180;
phi0   = 0*pi/180;

%% ====================================
% element size (microstrip)
W = 0.5 * (c / (19.45e9));          % patch width

%% ====================================
% 6-bit phase quantization
dq = 5.625*pi/180;

%% ====================================
% SA parameters
T0 = 1;
Tend = 1e-4;
alpha = 0.98;
Niter = 200;
K = 5;

%% ====================================
% element coordinates
aa = (0:m-1)*d;
bb = (0:n-1)*d;
[XX,YY] = meshgrid(bb,aa);

k = 2*pi/lambda;

%% ====================================
% pre-computation speedup
% uv straight line
u0 = sin(theta0)*cos(phi0);
v0 = sin(theta0)*sin(phi0);
u = linspace(-1,1,NA);
v = linspace(-1,1,NA);

% two straight lines
U1 = u;
V1 = v0*ones(1,NA); % u scan
U2 = u0*ones(1,NA);
V2 = v;             % v scan

% pre-computation partial array factor
S_u = exp(1j*k*(XX(:)*U1 + YY(:)*V1));
S_v = exp(1j*k*(XX(:)*U2 + YY(:)*V2));

%% ====================================
% scan angle theoretic phase initialization
phase_scan = -k * ( ...
    XX*sin(theta0)*cos(phi0) + ...
    YY*sin(theta0)*sin(phi0) );

phase = round(phase_scan(:)/dq)*dq;

%% ====================================
% initial fitness
Fit = func_gain_msll( ...
    lambda, W, m, n, d, ...
    theta0, phi0, NA, phase, phase_scan, S_u, S_v);

bestPhase = phase;
bestFit = Fit;
trace = [];

%% ====================================
% ========== SA main cycle ==========
T = T0;
while T > Tend
    for it = 1:Niter
        newPhase = phase;
        idx = randperm(L,K);
        for ii = idx
            newPhase(ii) = newPhase(ii) + sign(randn)*dq;
        end

        newPhase = round(newPhase/dq)*dq;

        newFit = func_gain_msll( ...
            lambda, W, m, n, d, ...
            theta0, phi0, NA, newPhase, phase_scan, S_u, S_v);

        dE = -(newFit - Fit);

        if dE < 0 || rand < exp(-dE/T)
            phase = newPhase;
            Fit = newFit;
        end

        if Fit > bestFit
            bestFit = Fit;
            bestPhase = phase;
        end

        trace(end+1) = bestFit;
    end

    T = T*alpha;
    fprintf('T = %.4f | Best Fit = %.2f dB\n', T, bestFit);
end

%% ====================================
% converge curve
figure;
plot(trace,'LineWidth',1.5);
grid on;
xlabel('Iteration');
ylabel('Fitness (|MSLL|)');
title('SA Gain-based Optimization');

%% ====================================
% ===== pattern verification（φ = φ0 sliced surface）=====
theta = linspace(-pi/2,pi/2,NA);

phase2D = reshape(bestPhase,m,n);

AF = zeros(1,NA);
EF = zeros(1,NA);

for ii = 1:NA
    AF(ii) = sum(sum(exp(1j*( ...
        k*( ...
        XX*sin(theta(ii))*cos(phi0) + ...
        YY*sin(theta(ii))*sin(phi0)) ...
        + phase2D ))));

    % microstrip element factor
    EF(ii) = cos(theta(ii)) .* ...
        sinc((k*W/2/pi)*sin(theta(ii))*cos(phi0));
end

Gain = abs(AF).^2 .* abs(EF).^2;
Gain_dB = 10*log10(Gain + 1e-3);

figure;
plot(theta*180/pi,Gain_dB,'LineWidth',1.5);
grid on;
xlabel('\theta (deg)');
ylabel('Gain (dB)');
title('\phi = \phi0° Plane Gain Pattern');
xlim([-90 90]);

bestPhase0 = mod(180*reshape(bestPhase,m,n)/pi,360);

%% ===== uv plane 3-D pattern=====
Nu = 181;
Nv = 181;
u = linspace(-1,1,Nu);
v = linspace(-1,1,Nv);

Gain_uv = nan(Nu,Nv);

for ii = 1:Nu
    for jj = 1:Nv
        if u(ii)^2 + v(jj)^2 <= 1
            AF = sum(sum(exp(1j*( ...
                k*(XX*u(ii) + YY*v(jj)) + phase2D ))));
            EF = sqrt(1-u(ii)^2-v(jj)^2);
            Gain_uv(ii,jj) = abs(AF)^2 * EF^2;
        end
    end
end

Gain_uv_dB = 10*log10(Gain_uv/max(Gain_uv(:))+1e-6);

figure;
surf(u,v,Gain_uv_dB,'EdgeColor','none');
xlabel('u'); ylabel('v'); zlabel('Gain (dB)');
title('uv-space 3D Gain Pattern');
colorbar; view(45,30);

%% ====================================
% ========= fitness fuction =========
function Fit = func_gain_msll( ...
    lambda, W, m, n, d, ...
    theta0, phi0, NA, phase0, phase_scan, S_u, S_v)
eps = 1e-9;
bottom = -60;
max_loss = 0.3;     % acceptable main lobe loss/ dB

phase = reshape(phase0,m,n);

aa = (0:m-1)*d;
bb = (0:n-1)*d;
[XX,YY] = meshgrid(bb,aa);

k = 2*pi/lambda;
w = exp(1j * phase0(:));

%% ===== main lobe gain =====
AF0 = sum(sum(exp(1j*( ...
    k*(XX*sin(theta0)*cos(phi0) + ...
       YY*sin(theta0)*sin(phi0)) ...
    + phase ))));

EF0 = cos(theta0) * ...
      sinc((k*W/2/pi)*sin(theta0)*cos(phi0));

AF_theory = sum(sum(exp(1j*( ...
    k*(XX*sin(theta0)*cos(phi0) + ...
       YY*sin(theta0)*sin(phi0)) ...
    + phase_scan ))));

G_actual = abs(AF0)^2 * abs(EF0)^2;
G_theory = abs(AF_theory)^2 * abs(EF0)^2;

G_actual_dB = 10*log10(G_actual + eps);
G_theory_dB = 10*log10(G_theory);

if (G_theory_dB - G_actual_dB) > max_loss
    Fit = 0;
    return;
end

%% ===== uv coordinates side lobes searching =====

Nu = NA;
Nv = NA;

u = linspace(-1,1,Nu);
v = linspace(-1,1,Nv);

u0 = sin(theta0)*cos(phi0);
v0 = sin(theta0)*sin(phi0);

Gain_u = zeros(1,Nu);   % u = u0 line
Gain_v = zeros(1,Nv);   % v = v0 line

%% ---- u = u0，scan v ----
for jj = 1:Nv
    AF = sum( w .* S_v(:,jj) );
    EF = sqrt(max(0,1-u0^2-v(jj)^2));
    Gain_u(jj) = abs(AF)^2 * EF^2;
end

%% ---- v = v0，scan u ----
for ii = 1:Nu
    AF = sum( w .* S_u(:,ii) );
    EF = sqrt(max(0,1-u(ii)^2-v0^2));
    Gain_v(ii) = abs(AF)^2 * EF^2;
end

%% ---- normalization ----
Gain_u_dB = 10*log10(Gain_u/max(Gain_u)+eps);
Gain_v_dB = 10*log10(Gain_v/max(Gain_v)+eps);

%% ---- main lobe elimination（u line）----
[~,mu] = max(Gain_u_dB);
lu = mu; ru = mu;
while lu>1  && Gain_u_dB(lu)>=Gain_u_dB(lu-1), lu=lu-1; end
while ru<Nu && Gain_u_dB(ru)>=Gain_u_dB(ru+1), ru=ru+1; end
Gain_u_dB(lu:ru) = bottom;

%% ---- main lobe elimination（v line）----
[~,mv] = max(Gain_v_dB);
lv = mv; rv = mv;
while lv>1  && Gain_v_dB(lv)>=Gain_v_dB(lv-1), lv=lv-1; end
while rv<Nv && Gain_v_dB(rv)>=Gain_v_dB(rv+1), rv=rv+1; end
Gain_v_dB(lv:rv) = bottom;

%% ---- maximum side lobe ----
MSLL = max( max(Gain_u_dB), max(Gain_v_dB) );
Fit  = abs(MSLL);

end
