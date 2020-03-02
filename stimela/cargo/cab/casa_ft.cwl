cwlVersion: v1.1 
class: CommandLineTool

requirements:
  EnvVarRequirement: 
    envDef:
      USER: root
  DockerRequirement:
    dockerPull: stimela/casa:1.2.0
  InlineJavascriptRequirement: {}
  InitialWorkDirRequirement:
    listing:
      - entry: $(inputs.vis)
        writable: true
      - entry: $(inputs.model)
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
              if (value.class == 'Directory') {
                values[key] = value.path;
              } else {
                if (key == 'model') {
                  var models = [];
                  for (var i in value) {
                    models.push(value[i].path)
                  }
                  if (inputs.nterms > 1) {
                    values[key] = models
                  } else {
                    values[key] = models[0]
                  }
                } else {
                  values[key] = value;
                  } 
              }
            }
        }
        return values;
      }
      task = crasa.CasaTask("ft", **args)
      task.run()

inputs:
  vis:
    type: Directory
    doc:  Name of input visibility file (MS)
  model:
    type: Directory
    doc: Name of input model image(s)
  field:
    type: string?
    doc: Field selection
    default: ""
  spw:
    type: string?
    doc: Spw selection
    default: ""
  nterms:
    type: int?
    default: 1
    doc: Number of terms used to model the sky
  complist:
    type: string?
    doc: Name of component list
    default: ""
  incremental:
    type: boolean
    default: false
    doc:  Add to the existing model visibility
  usescratch:
    type: boolean
    default: true
    doc:  If True predicted visibility is stored in MODEL_DATA column

outputs:
  msname_out:
    type: Directory
    outputBinding:
      outputEval: $(inputs.vis)
