function [CSX, params] = CreateSplitDoubleRing(CSX, object, translate, rotate);
  box_start = [0, 0, object.lz/2];
  box_stop = -box_start;
  R1 = object.R1;
  w1 = object.w1;
  R2 = object.R2;
  w2 = object.w2;
  Lres1 = object.Lres1;
  Lres2 = object.Lres2;
  lz = object.lz;
  res_width1 = 2*w1;
  res_width2 = 2*w2;
  ring_start = [0, 0, -object.lz/2];
  ring_stop = [0, 0, object.lz/2];
  ringmaterial = object.material.name;
  bmaterial = object.bmaterial.name;
  bstart = [-object.UClx/2, -object.UCly/2, -object.lz/2];
  bstop  = -bstart;
  CSX = AddBox(CSX, bmaterial, object.prio, bstart, bstop,...
            'Transform', {'Rotate_Z', rotate, 'Translate', translate});
  if object.complemential;
    try;
    CSX = AddMaterial(CSX, 'air');
    CSX = SetMaterialProperty(CSX, 'air', 'Epsilon', 1);
    catch lasterror;
    end;
    ringmaterial = 'air';
    bmaterial = object.material.name;
    bstart = [-object.UClx/2, -object.UCly/2, -object.lz/2];
    bstop  = -bstart;
    CSX = AddBox(CSX, bmaterial, object.prio, bstart, bstop,...
            'Transform', {'Rotate_Z', rotate, 'Translate', translate});
  end;
  CSX = AddCylindricalShell(CSX, ringmaterial, object.prio+1, ...
        ring_start, ring_stop, R1-w1/2, w1,...
        'Transform', {'Rotate_Z', rotate, 'Translate', translate});
  CSX = AddCylindricalShell(CSX, ringmaterial, object.prio+1, ...
        ring_start, ring_stop, R2-w2/2, w2,...
        'Transform', {'Rotate_Z', rotate, 'Translate', translate});
  ocenter = [object.xycenter(1:2), 0] + translate;
  inner1 = [-R1, -Lres1/2, -lz/2];
  inner2 = [-R1+w1, Lres1/2, lz/2];
  outer1 = [-R2, -Lres2/2, -lz/2];
  outer2 = [-R2+w2, Lres2/2, lz/2];

  CSX = AddBox(CSX, bmaterial, object.prio+2, inner1, inner2, ...
    'Transform', {'Rotate_Z', rotate+0, 'Translate', translate});
  CSX = AddBox(CSX, bmaterial, object.prio+2, outer1, outer2, ...
    'Transform', {'Rotate_Z', rotate+pi, 'Translate', translate});
    
  params = ['# circular split-rings made of ',  ringmaterial, ' at center position x = ', num2str(ocenter(1)), ' y = ', num2str(ocenter(2)), ' z = ' num2str(ocenter(3)), '\n' ...
            '# radius R1, R2=', num2str(R1,'%.10f') ', ' num2str(R2,'%.10f'), ' ringwidths w1, w2=', num2str(w1,'%.10f'), ', ', num2str(w2,'%.10f'), ', background material ', bmaterial, '\n' ...
            '# gap of width ', num2str(Lres1) ' and ' num2str(Lres2) '.\n'];
  return;
end