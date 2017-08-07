function windings(UCDim, fr4_thickness, L, w, g, N, alpha, eps_subs, tand, mesh_refinement, complemential);
  physical_constants;
  UC.layer_td = 1;
  UC.layer_fd = 1;
  UC.td_dumps = 1;
  UC.fd_dumps = 1;
  UC.s_dumps = 1;
  UC.nf2ff = 0;
  if uname().nodename == "Xeon";
    midstr = "/";
    printf("Running job on XEON \n");
  else;
    midstr = "/git_layerbased/";
  endif;
  UC.s_dumps_folder = ["~/Arbeit/openEMS" midstr "layerbased_metamaterials/Ergebnisse/SParameters"];
  UC.s11_filename_prefix = ["UCDim_" num2str(UCDim) "_lz_" num2str(fr4_thickness) "_L_" num2str(L) "_w_" num2str(w) "_g_" num2str(g) "_N_" num2str(N) "_eps_" num2str(eps_subs) "_tand_" num2str(tand)];
  complemential = complemential;
  if complemential;
    UC.s11_filename_prefix = horzcat(UC.s11_filename_prefix, "_comp");
  endif;
  UC.s11_filename = "Sparameters_";
  UC.s11_subfolder = "windings";
  UC.run_simulation = 1;
  UC.show_geometry = 1;
  UC.grounded = 1;
  UC.unit = 1e-3;
  UC.f_start = 1e9;
  UC.f_stop = 20e9;
  UC.lx = UCDim;
  UC.ly = UCDim;
  UC.lz = c0/ UC.f_start / 2 / UC.unit;
  UC.dz = c0 / (UC.f_stop) / UC.unit / 20;
  min_dxy = min(g, w);
  UC.dx = min_dxy/4;
  UC.dy = UC.dx;
  UC.dump_frequencies = [2.4e9, 5.2e9, 16.5e9];
  UC.s11_delta_f = 10e6;
  UC.EndCriteria = 1e-3;
  if uname().nodename == "Xeon";
    UC.SimPath = ["/media/stefan/Daten/openEMS/" UC.s11_subfolder "/" UC.s11_filename_prefix];
    UC.ResultPath = ["~/Arbeit/openEMS/layerbased_metamaterials/Ergebnisse"];
  else;
  UC.SimPath = ["/mnt/hgfs/E/openEMS/layerbased_metamaterials/Simulation/" UC.s11_subfolder "/" UC.s11_filename_prefix];
  UC.ResultPath = ["~/Arbeit/openEMS/git_layerbased/layerbased_metamaterials/Ergebnisse"];
  endif;
  UC.SimCSX = "geometry.xml";
  if UC.run_simulation;
    confirm_recursive_rmdir(0);
    [status, message, messageid] = rmdir(UC.SimPath, 's' ); % clear previous directory
    [status, message, messageid] = mkdir(UC.SimPath ); % create empty simulation folder
  endif;
  FDTD = InitFDTD('EndCriteria', UC.EndCriteria);
  FDTD = SetGaussExcite(FDTD, 0.5*(UC.f_start+UC.f_stop),0.5*(UC.f_stop-UC.f_start));
  BC = {'PMC', 'PMC', 'PEC', 'PEC', 'PML_8', 'PML_8'}; % boundary conditions
  FDTD = SetBoundaryCond(FDTD, BC);
  rectangle.name = "backplate";
  rectangle.lx = UCDim;
  rectangle.ly = UCDim;
  rectangle.lz = 0.5;
  rectangle.rotate = 0;
  rectangle.prio = 2;
  rectangle.xycenter = [0, 0];
  rectangle.material.name = "copper";
  #rectangle.material.Kappa = 56e6;
  rectangle.material.type = "const";
  rectangle.material.Kappa = 56e6;

  # Substrate
  substrate.name = "FR4 substrate";
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
  substrate.material.f0 = 10e9;
  substrate.zrefinement = sqrt(eps_subs);

  # circle
  coil.name = "coil";
  coil.lz = 0.05;
  coil.rotate = 0;
  coil.material.name = "copper_coil";
  coil.material.Kappa = 56e6;
  coil.material.type = "const";
  coil.bmaterial.name = "air";
  coil.bmaterial.type = "const";
  coil.bmaterial.Epsilon = 1;
  coil.L = L;
  coil.w = w;
  coil.g = g;
  coil.N = N;
  coil.alpha = alpha;
  coil.UClx = UCDim;
  coil.UCly = UCDim;
  coil.prio = 2;
  coil.xycenter = [0, 0];
  coil.complemential = complemential;
  
  layer_list = {{@CreateUC, UC}; {@CreateRect, rectangle};
                                 {@CreateRect, substrate};
                                 {@CreateCoil, coil}
                                 };
  material_list = {substrate.material, rectangle.material, coil.material, coil.bmaterial};
  [CSX, mesh, param_str] = stack_layers(layer_list, material_list);
  if UC.nf2ff == 0;
    [CSX, port] = definePorts(CSX, mesh, UC.f_start);
  elseif UC.nf2ff == 1;
    [CSX, port, nf2ff] = definePortsNF2FF(CSX, mesh, UC);
    phase_center_z = 0
    for i = 2:(size(layer_list)(1));
      for j = 1:(size(layer_list{i}(1)));
        object = layer_list{i}{j, 2};
        phase_center_z -= object.lz;
      endfor;
    endfor;
  endif;
  UC.param_str = param_str;
  [CSX] = defineFieldDumps(CSX, mesh, layer_list, UC);
  WriteOpenEMS([UC.SimPath '/' UC.SimCSX], FDTD, CSX);
  if UC.show_geometry;
    CSXGeomPlot([UC.SimPath '/' UC.SimCSX]);
  endif;
  if UC.run_simulation;
    openEMS_opts = '--engine=multithreaded --numThreads=6';#'-vvv';
    #Settings = ["--debug-PEC", "--debug-material"];
    Settings = ["--disable-dumps"];
    RunOpenEMS(UC.SimPath, UC.SimCSX, openEMS_opts, Settings);
  endif;
  doPortDump(port, UC);
  if UC.nf2ff == 1;
    freq = [2.4e9, 5.2e9, 12e9, 15e9];
    phi = linspace(0, 2*pi, 100);
    theta = linspace(0, pi, 100);
    for f0 = freq;
      printf(['calculating 3D far field for f=' num2str(f0) "\n"]);
      printf(["Using phase center x=0, y=0, z=" num2str(phase_center_z) "\n"]);
      nf2ff = CalcNF2FF(nf2ff, UC.SimPath, f0, theta, phi, 'Mode', UC.run_simulation, 'Center', [0, 0, phase_center_z*2]);
      printf(["WARNING: Shifted the phase-center by a factor of two for optical reasons \n"]);
      E_far_normalized = nf2ff.E_norm{1}/max(nf2ff.E_norm{1}(:));
      DumpFF2VTK([UC.SimPath '/NF2FF_f_' num2str(f0/1e9) '_GHz.vtk'],E_far_normalized,theta*180/pi, phi*180/pi,'scale',1e-2);
      printf(['Far-field pattern for f = ' num2str(f0) ' written to *.vtk\n']);
    endfor;
  endif;
endfunction;