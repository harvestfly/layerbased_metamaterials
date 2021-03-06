function [CSX, params] = CreateBroadbandChipres(CSX, object, translate, rotate);
% Broadband absorber geometry of
% : Appl. Phys. Lett.112, 021605 (2018); doi: 10.1063/1.5004211 

  UClx = object.UClx;
  UCly = object.UCly;
  L = object.L;
  w = object.w;
  R = object.R;
  a = object.a;
  
  lz = object.lz;
  material = object.material.name;
  bmaterial = object.bmaterial.name;
  resistormaterial = object.resistormaterial.name;
  gap1 = [+a/2, -a/2, -lz/2];
  gap2 = [R, +a/2, +lz/2];
  
  resistor1 = [L, -a/2, -lz/2];
  resistor2 = [L+a, a/2, lz/2];

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
    material = 'air';
    bmaterial = object.material.name;
    bstart = [-object.UClx/2, -object.UCly/2, -object.lz/2];
    bstop  = -bstart;
    CSX = AddBox(CSX, bmaterial, object.prio, bstart, bstop,...
            'Transform', {'Rotate_Z', rotate, 'Translate', translate});
  end;
  CSX = AddCylinder(CSX, material, object.prio, [0,0,-lz/2],[0,0,lz/2], R, ...
  'Transform', {'Rotate_Z', rotate, 'Translate', translate});

  for rot = (0:3)*pi/2+pi/4;
    CSX = AddBox(CSX, bmaterial, object.prio+1,...
        gap1, gap2, 'Transform', {'Rotate_Z', rotate+rot, 'Translate', translate});
    CSX = AddBox(CSX, resistormaterial, object.prio+2, resistor1, resistor2,'Transform', {'Rotate_Z', rotate+rot, 'Translate', translate});
  
  end;
    
 
  ocenter = [object.xycenter(1:2), 0] + translate;
  params = ['# broadband chipresonator absorber made of ',  material, ' at center position x = ', num2str(ocenter(1)), ' y = ', num2str(ocenter(2)), ' z = ' num2str(ocenter(3)), '\n'];
  return;
end