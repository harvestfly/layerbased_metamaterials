clear;
clc;
physical_constants;
addpath("./libraries");

rect_gap = 0;

UCDim = 20;
complemential = 0;
fr4_thickness = 2;
eps_FR4 = 4.1;
tand = 0.015;
number = 10;
fr4_thickness = 2;
rectangular_Hpatch(UCDim, 19, 19, 1, 1, fr4_thickness, eps_FR4, tand);

