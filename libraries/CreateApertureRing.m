function [CSX, params] = CreateApertureRing(CSX, object, translate, rotate);
  object = object;
  box_start = [0, 0, object.lz/2];
  box_stop = -box_start;
  R1 = object.R1;
  w1 = object.w1;
  R2 = object.R2;
  w2 = object.w2;
  gap = object.gap;
  ring_start = [0, 0, -object.lz/2];
  ring_stop = [0, 0, object.lz/2];
  ringmaterial = object.material.name;
  CSX = AddMaterial(CSX, "air");
  CSX = SetMaterialProperty(CSX, "air", "Epsilon", 1);
  holematerial = "air";
  bstart = [-object.UClx/2+gap/2, -object.UCly/2+gap/2, -object.lz/2];
  bstop  = -bstart;
  CSX = AddBox(CSX, ringmaterial, object.prio, bstart, bstop,
            'Transform', {'Rotate_Z', rotate, 'Translate', translate});

  CSX = AddCylinder(CSX, holematerial, object.prio+1, 
        ring_start, ring_stop, R1-w1, 
        'Transform', {'Rotate_Z', rotate, 'Translate', translate});
  CSX = AddCylindricalShell(CSX, ringmaterial, object.prio+2, 
        ring_start, ring_stop, R2-w2/2, w2,
        'Transform', {'Rotate_Z', rotate, 'Translate', translate});
  ocenter = [object.xycenter(1:2), 0] + translate;
  params = ["# circular aperture with ring made of "  ringmaterial " at center position x = " num2str(ocenter(1)) " y = " num2str(ocenter(2)) " z = " num2str(ocenter(3)) "\n" \
            "# radius R1, R2=" num2str(R1) ", " num2str(R2) " ringwidths w1, w2=" num2str(w1) ", " num2str(w2) ", rect material " holematerial " edge gap = " num2str(gap) "\n"];
  return;
endfunction