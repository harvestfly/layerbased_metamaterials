function double_ring_Ezgi(UCDim, fr4_thickness, R1, w1, R2, w2, eps_subs, tand, mesh_refinement, complemential, swap);
  physical_constants;
  UC.layer_td = 1;
  UC.layer_fd = 1;
  UC.td_dumps = 1;
  UC.fd_dumps = 1;
  UC.s_dumps = 1;
  UC.s_dumps_folder = "~/Arbeit/openEMS/git_layerbased/layerbased_metamaterials/Ergebnisse/SParameters";
  UC.s11_filename_prefix = ["UCDim_" num2str(UCDim) "_lz_" num2str(fr4_thickness) "_R1_" num2str(R1) "_w1_" num2str(w1) "_R2_" num2str(R2) "_w2_" num2str(w2) "_eps_" num2str(eps_subs) "_tand_" num2str(tand) "_swap_" num2str(swap)];
  complemential = complemential;
  if complemential;
    UC.s11_filename_prefix = horzcat(UC.s11_filename_prefix, "_comp");
  endif;
  UC.s11_filename = "Sparameters_";
  UC.s11_subfolder = "double_ring_Ezgi_smooth";
  UC.run_simulation = 0;
  UC.show_geometry = 0;
  UC.grounded = 0;
  UC.unit = 1e-3;
  UC.f_start = 1e9;
  UC.f_stop = 20e9;
  UC.lx = UCDim;
  UC.ly = UCDim;
  UC.lz = c0/ UC.f_start / 2 / UC.unit;
  UC.dz = c0 / (UC.f_stop) / UC.unit / 20;
  UC.dx = UC.dz/3/mesh_refinement;
  UC.dy = UC.dx;
  UC.dump_frequencies = [3.1e9, 5.2e9, 7.5e9];
  UC.s11_delta_f = 5e6;
  UC.EndCriteria = 5e-4;
  UC.SimPath = ["/mnt/hgfs/E/openEMS/layerbased_metamaterials/Simulation/" UC.s11_subfolder "/" UC.s11_filename_prefix];
  UC.SimCSX = "geometry.xml";
  UC.ResultPath = ["~/Arbeit/openEMS/git_layerbased/layerbased_metamaterials/Ergebnisse"];
  if UC.run_simulation;
    confirm_recursive_rmdir(0);
    [status, message, messageid] = rmdir(UC.SimPath, 's' ); % clear previous directory
    [status, message, messageid] = mkdir(UC.SimPath ); % create empty simulation folder
  endif;
  FDTD = InitFDTD('EndCriteria', UC.EndCriteria);
  FDTD = SetGaussExcite(FDTD, 0.5*(UC.f_start+UC.f_stop),0.5*(UC.f_stop-UC.f_start));
  BC = {'PMC', 'PMC', 'PEC', 'PEC', 'PML_8', 'PML_8'}; % boundary conditions
  FDTD = SetBoundaryCond(FDTD, BC);
#  rectangle.name = "backplate";
#  rectangle.lx = UCDim;
#  rectangle.ly = UCDim;
#  rectangle.lz = 0.5;
#  rectangle.rotate = 0;
#  rectangle.prio = 2;
#  rectangle.xycenter = [0, 0];
#  rectangle.material.name = "copper";
#  #rectangle.material.Kappa = 56e6;
#  rectangle.material.type = "const";
#  rectangle.material.EpsilonPlasmaFrequency = 2.5e14;
#  rectangle.material.EpsilonRelaxTime = 1.6e-13;
#  rectangle.material.Kappa = 56e6;

  # Substrate
  substrate.name = "FR4";
  substrate.lx = UC.lx;
  substrate.ly = UC.ly;
  substrate.lz = fr4_thickness;
  substrate.rotate = 0;
  substrate.prio = 2;
  substrate.xycenter = [0, 0];
  substrate.material.name = "FR4";
  substrate.material.type = "const";
  substrate.material.Epsilon = eps_subs;
  substrate.material.tand = tand;
  substrate.zrefinement = sqrt(eps_subs/4);

  # circle
  dblring.name = "double rings";
  dblring.lz = 0.05;
  dblring.rotate = 0;
  dblring.material.name = "copperRings";
#  dblring.material.Kappa = 56e6;
  dblring.material.EpsilonPlasmaFrequency = 2.5e14;
  dblring.material.EpsilonRelaxTime = 1.6e-13;
  dblring.material.Kappa = 56e6;
  dblring.material.type = "const";
  dblring.bmaterial.name = "air";
  dblring.bmaterial.type = "const";
  dblring.bmaterial.Epsilon = 1;
  dblring.R1 = R1;
  dblring.R2 = R2;
  dblring.w1 = w1;
  dblring.w2 = w2;
  dblring.UClx = UCDim;
  dblring.UCly = UCDim;
  dblring.prio = 2;
  dblring.xycenter = [0, 0];
  dblring.complemential = complemential;


  layer_list = {{@CreateUC, UC}; {@CreateRect, substrate};
                                 {@CreateDoubleRing, dblring}
                                 };
  material_list = {substrate.material, dblring.material, dblring.bmaterial};
  if swap == 1;
    new_layer_list{1,1} = layer_list{1,1};
    sizeL = size(layer_list)(1);
    for idx = 0:sizeL-2;
      new_layer_list{idx+2,1} = layer_list{sizeL-idx};
    endfor;
    layer_list = new_layer_list;
    [CSX, mesh, param_str] = stack_layers(layer_list, material_list);
  else;
    [CSX, mesh, param_str] = stack_layers(layer_list, material_list);
  endif;
 
  
  [CSX, port] = definePorts(CSX, mesh, UC.f_start);
  UC.param_str = param_str;
  [CSX] = defineFieldDumps(CSX, mesh, layer_list, UC);
  WriteOpenEMS([UC.SimPath '/' UC.SimCSX], FDTD, CSX);
  if UC.show_geometry;
    CSXGeomPlot([UC.SimPath '/' UC.SimCSX]);
  endif;
  if UC.run_simulation;
    openEMS_opts = '';#'-vvv';
    #Settings = ["--debug-PEC", "--debug-material"];
    Settings = ["--numThreads=3"];
    RunOpenEMS(UC.SimPath, UC.SimCSX, openEMS_opts, Settings);
  endif;
  doPortDump(port, UC);
endfunction;