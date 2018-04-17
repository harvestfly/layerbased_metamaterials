function [CSX, port] = definePortsTL(CSX, mesh, f_start, polarization='y');
  physical_constants;
  n_cells_to_edge = 20;
  p1 = [mesh.x(1), mesh.y(1), mesh.z(n_cells_to_edge)];
  lambda_max = C0/f_start;
  [zmax, idx] = min(abs(mesh.z+lambda_max/3));
  p2 = [mesh.x(end), mesh.y(end), mesh.z(n_cells_to_edge+2)];
  p3 = p1;
  p4 = [mesh.x(end), mesh.y(end), 0];
  func_E{1} = 0;
  func_E{2} = -1;
  func_E{3} = 0;
  func_H{1} = 1;
  func_H{2} = 0;
  func_H{3} = 0;
  if strcmp(polarization, 'x');
    func_E{1} = 1;
    func_E{2} = 0;
    func_E{3} = 0;
    func_H{1} = 0;
    func_H{2} = 1;
    func_H{3} = 0;
  end; 
  [CSX, port{1}] = AddWaveGuidePort(CSX, 10, 1, p1, p2, 2, func_E, func_H, 1, 1);
  [CSX, port{2}] = AddWaveGuidePort(CSX, 10, 2, p3, p4, 2, func_E, func_H, 1, 0);
end