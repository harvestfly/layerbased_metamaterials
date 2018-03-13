clear;
clc;
physical_constants;
addpath('./libraries');
addpath('./libraries/optimize');

complemential = 0;

eps_subs = 4.4;
tand = 0.02;

UCDim = 14.0;
fr4_thickness = 3.2;
mesh_refinement = 2;
L1 = 4.;
L2 = 3;

gapwidth = 0.60;
gapwidth2 = gapwidth;
reswidth = 0.5;

rho = 3.25;
Res1 = 210;
Res2 = 15;
fcenter = [8.5e9];
fwidth = [4e9];
absorption = [];


for rho = [3.25, 3, 2.75];
for Res1 = [300,275, 250, 225, 210, 200, 190];
for Res2 = [100, 80, 60, 50, 40, 30, 20, 10];
  absorption = [absorption, ...
  optimize_rect_broadband_chipres1(UCDim, fr4_thickness, L1, L2, rho, gapwidth, gapwidth2,...
reswidth, Res1, Res2, eps_subs, tand, mesh_refinement, complemential, fcenter, fwidth)];
end;
end;end;
display(['The minimum integrated reflectance from ' num2str((fcenter-fwidth)/1e9)...
 ' GHz to ' num2str((fcenter+fwidth)/1e9) ' GHz is ' num2str(min(absorption))]);