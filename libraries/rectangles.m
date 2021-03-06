function rectangles(UCDim, fr4_thickness, N, L, dL, eps_FR4, tand, complemential);
  physical_constants;
  UC.layer_td = 0;
  UC.layer_fd = 0;
  UC.td_dumps = 0;
  UC.fd_dumps = 0;
  UC.s_dumps = 1;
  machine = uname().nodename;
  if length(machine) == 4;
    if machine == "Xeon";
      UC.s_dumps_folder = "~/Arbeit/openEMS/layerbased_metamaterials/Ergebnisse/SParameters";
    endif;
  else;
    UC.s_dumps_folder = "~/Arbeit/openEMS/git_layerbased/layerbased_metamaterials/Ergebnisse/SParameters";
  endif;
  UC.s11_filename_prefix = ["UCDim_" num2str(UCDim) "_lz_" num2str(fr4_thickness) "_rectL_" num2str(L) "_N_" num2str(N) "_dL_" num2str(dL) "_epsFR4_" num2str(eps_FR4) "_tand_" num2str(tand)];
  complemential = complemential;
  if complemential;
    UC.s11_filename_prefix = horzcat(UC.s11_filename_prefix, "_comp");
  endif;
  UC.s11_filename = "Sparameters_";
  UC.s11_subfolder = "rectangles";
  UC.run_simulation = 1;
  UC.show_geometry = 1;
  UC.grounded = 1;
  UC.unit = 1e-3;
  UC.f_start = 1e9;
  UC.f_stop = 20e9;
  UC.lx = UCDim;
  UC.ly = UCDim;
  UC.lz = c0/ UC.f_start / 3 / UC.unit;
  UC.dz = c0 / (UC.f_stop) / UC.unit / 20;
  UC.dx = UC.dz/3;
  UC.dy = UC.dx;
  UC.dump_frequencies = [2.4e9, 5.2e9, 16.5e9];
  UC.s11_delta_f = 10e6;
  UC.EndCriteria = 5e-4;
  UC.SimCSX = "geometry.xml";
  if length(machine) == 4;
    if machine == "Xeon";
      UC.SimPath = ["/media/stefan/Daten/openEMS/" UC.s11_subfolder "/" UC.s11_filename_prefix];
      UC.ResultPath = ["~/Arbeit/openEMS/layerbased_metamaterials/Ergebnisse"];
    endif;
  else;
    UC.SimPath = ["/mnt/hgfs/E/openEMS/layerbased_metamaterials/Simulation/" UC.s11_subfolder "/" UC.s11_filename_prefix];
    UC.ResultPath = ["~/Arbeit/openEMS/git_layerbased/layerbased_metamaterials/Ergebnisse"];
  endif;
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
  rectangle.material.type = "const";
  rectangle.material.Kappa = 56e6;
 

  # Substrate
  substrate.name = "FR4 substrate";
  substrate.lx = UC.lx;
  substrate.ly = UC.ly;
  substrate.UClx = UC.lx;
  substrate.UCly = UC.ly;
  substrate.lz = fr4_thickness;
  substrate.rotate = 0;
  substrate.prio = 2;
  substrate.xycenter = [0, 0];
  substrate.material.name = "FR4";
  substrate.material.type = "const";
  substrate.material.Epsilon = eps_FR4;
  substrate.material.tand = 0.015;
  substrate.material.f0 = 5e9;


  rectpatch.name = "CopperRectangle";
  rectpatch.lx = L;
  rectpatch.ly = L;
  rectpatch.UClx = UCDim;
  rectpatch.UCly = UCDim;
  rectpatch.lz = 0.05;
  rectpatch.rotate = 0;
  rectpatch.prio = 2;
  rectpatch.xycenter = [0,0];
  rectpatch.material.name = "copper";
  rectpatch.material.type = "const";
  rectpatch.material.Kappa = 56e6;
  
  rectpatch.bmaterial.name = "FR4";
  rectpatch.bmaterial.type = "const";
  rectpatch.bmaterial.Epsilon = eps_FR4;
  rectpatch.bmaterial.tand = 0.015;
  rectpatch.bmaterial.f0 = 5e9;
  
  outermost.bmaterial.name = "air";
  outermost.bmaterial.type = "const";
  outermost.bmaterial.Epsilon = 1;
  layer_list = cell(2+N*2,1);
  layer_list(1:2,1) = {{@CreateUC, UC}; 
                       {@CreateRect, rectangle};};

  for i = 1:N-1;
    rectpatch.lx -= dL;
    rectpatch.ly -= dL;
    substrate.lz = fr4_thickness * (1 - 0.33 * i/N);
    layer_list(i*2+1,1) = {{@CreateRect, substrate}};
    layer_list(i*2+2,1) = {{@CreateRectangle, rectpatch}};
  endfor;
  rectpatch.bmaterial = outermost.bmaterial;
  layer_list(i*2+3,1) = {{@CreateRect, substrate}};
  layer_list(i*2+4,1) = {{@CreateRectangle, rectpatch}};
                  
  material_list = {substrate.material, rectpatch.material, outermost.bmaterial};
  [CSX, mesh, param_str] = stack_layers(layer_list, material_list);
  [CSX, port] = definePorts(CSX, mesh, UC.f_start);
  UC.param_str = param_str;
  [CSX] = defineFieldDumps(CSX, mesh, layer_list, UC);
  WriteOpenEMS([UC.SimPath '/' UC.SimCSX], FDTD, CSX);
  if UC.show_geometry;
    CSXGeomPlot([UC.SimPath '/' UC.SimCSX]);
  endif;
  if UC.run_simulation;
    openEMS_opts = '--engine=multithreaded --numThreads=3';#'-vvv';
    #Settings = ["--debug-PEC", "--debug-material"];
    Settings = [""];
    RunOpenEMS(UC.SimPath, UC.SimCSX, openEMS_opts, Settings);
  endif;
  doPortDump(port, UC);
endfunction;
