function [port] = dumpS11(port, UC);
  freq = linspace(UC.f_start, UC.f_stop, round((UC.f_stop-UC.f_start)/UC.s11_delta_f));
  Sim_Path = UC.SimPath;
  s11_filename_prefix = UC.s11_filename_prefix;
  s11_filename = UC.s11_filename;
  s11_subfolder = UC.s11_subfolder;
  port1_zcoordinate = UC.port1_zcoordinate;
  port2_lgth = UC.port2_lgth;
  lastz = UC.lastz;
  params = UC.param_str;
  port{1} = calcPort(port{1}, Sim_Path, freq, 'RefImpedance', 376.73);%, 'RefImpedance', 130
  port{2} = calcPort(port{2}, Sim_Path, freq, 'RefImpedance', 376.73);%, 'RefImpedance', 130
  Z1 = port{1}.uf.tot ./ port{1}.if.tot;
  s11 = port{1}.uf.ref ./ (port{1}.uf.inc);
  Z2 = port{2}.uf.tot ./ port{2}.if.tot;
  s22 = port{2}.uf.ref ./ (port{2}.uf.inc);
  s21 = port{2}.uf.inc./port{1}.uf.inc;
  display("\nCalculating impedance from S11-Parameter\n");
  try;
      s11 = s11.* exp(-1j*UC.unit*(port1_zcoordinate-lastz)*2* freq*2*pi/3e8);
      s21 = s21.* exp(-1j*UC.unit*(port2_lgth)*freq*2*pi/3e8);
  catch lasterror;
      display("\n Could not find UC.lastz \n");
  end;
  Zin = 376.73 .* sqrt(((1+s11) .**2-s21.**2)./ ((1-s11).**2-s21.**2));
  U1 = port{2}.uf.tot;
  I1 = port{2}.if.tot;
  s11_filename = ['S11_f_' s11_filename_prefix '.txt'];
  s21_filename = ['S21_f_' s11_filename_prefix '.txt'];
  s_folder = [UC.ResultPath '/SParameters/' s11_subfolder];
  if not(exist(s_folder, 'dir'));
    display('Folder for S11 output did not exist.');
    display(['Calling: mkdir ' s_folder]);
    mkdir(s_folder);
  else;
    display('Folder for S11 output found.\n');
    display(s_folder);
  end;
  outfile = fopen([s_folder '/' s11_filename], 'w+');
  fprintf(outfile, [params]);
  fprintf(outfile, ['# Port position is z = ' num2str(port1_zcoordinate) ' m times ' num2str(UC.unit) '\n']);
try;
    fprintf(outfile, ['# closest structure elements have z = ' num2str(lastz) ' m times ' num2str(UC.unit) '\n']);
    fprintf(outfile, ['# distance D used for S11 phase-correction (exp(1j*omega*D/c0) is D = ' num2str((port1_zcoordinate-lastz)*UC.unit) ' m.\n']);
catch lasterror;
end;
  fprintf(outfile, '# Re/Im parts of the scattering parameters S11 (refl.) and S21 (transm.) and the real and imaginary part of the impedance as a function of frequency \n');
  fprintf(outfile, '# first column is frequency, second and third columns are Re/Im of S11 and S21, respectively.\n');
  for i=1:size(s11,2);
      fprintf(outfile, '%f, %f, %f, %f, %f, %f, %f ', freq(1, i), real(s11(1, i)), imag(s11(1,i )), real(s21(1,i )), imag(s21(1,i )), real(Zin(1,i)), imag(Zin(1,i)));
      fprintf(outfile, '\n');
  end;
  fclose(outfile);
  xlabel = '"$ f\\; [\\mathrm{GHz}]$"';
  ylabelS11 = '"$ 20\\log|S_{11}|$"';
  ylabelS21 = '"$ 20\\log|S_{21}|$"';
  system(['python3 ./python_scripts/S11_plot.py --infile ' s11_filename ' --xlabel ' xlabel ' --ylabel ' ylabelS11 ' --folder ' s_folder ' --outfile ' s11_filename ' --Xaxis ' num2str(0) ' --Yaxis ' num2str(1)]);
  if UC.grounded == 0;
    system(['python3 ./python_scripts/S11_plot.py --infile ' s11_filename ' --xlabel ' xlabel ' --ylabel ' ylabelS21 ' --folder ' s_folder ' --outfile ' s21_filename ' --Xaxis ' num2str(0) ' --Yaxis ' num2str(3)]);
  end;
  return;
end
