cwlVersion: v1.1
class: CommandLineTool

requirements:
  EnvVarRequirement:
    envDef:
      USER: root
  DockerRequirement:
    dockerPull: stimela/casa:1.2.5
  InlineJavascriptRequirement: {}
  InitialWorkDirRequirement:
    listing:
      - entry: $(inputs.fitsimage)
  InplaceUpdateRequirement:
    inplaceUpdate: true

baseCommand: python

arguments:
  - prefix: -c
    valueFrom: |
      from __future__ import print_function
      import Crasa.Crasa as crasa
      import sys 

      # JavaScript uses lowercase for bools
      true = True
      false = False
      null = None

      args = ${
        var values = {}; 

        for (var key in inputs) {
          var value = inputs[key];
          if (value) {
            if (value.class == "File") {
              values[key] = value.path;
            } else {
              values[key] = value;
            }
          }
        }
        return values;
      }
      task = crasa.CasaTask("importfits", **args)
      task.run()

inputs:
  fitsimage:
    type: File
    doc: Name of input image FITS file
  imagename:
    type: string
    doc: Name of output CASA image
  whichrep:
    type: int?
    doc: If fits image has multiple coordinate reps, choose one
  whichhdu:
    type: int?
    doc: If its file contains multiple images, choose one (0 = first HDU, -1 = first
      valid image).
  zeroblanks:
    type: boolean?
    doc: Set blanked pixels to zero (not NaN)
  overwrite:
    type: boolean?
    doc: Overwrite pre-existing imagename
  defaultaxesvalues:
    type: int[]?
    doc: List of values to assign to added degenerate axes defaultaxes==True (ra,dec,freq,stokes)
  beam:
    type: float[]?
    doc: List of values to be used to define the synthesized beam [BMAJ,BMIN,BPA] (as in the FITS keywords)

outputs:
  image_out:
    type: Directory
    doc: Output CASA image
    outputBinding:
      glob: $(inputs.imagename)                                                                                                                                                                                
