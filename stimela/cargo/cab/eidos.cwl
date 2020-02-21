cwlVersion: v1.1
class: CommandLineTool

requirements:
  DockerRequirement:
    dockerPull: stimela/eidos:1.2.0
  InlineJavascriptRequirement: {}
  InplaceUpdateRequirement:
    inplaceUpdate: true

baseCommand: eidos

inputs:
  pixels:
    type: int
    doc: Number of pixels on one side
    inputBinding:
      prefix: --pixels
  freq:
    type: string
    doc: A single freq, or the start, end freqs, and channel width in MHz
    inputBinding:
      prefix: --freq
      valueFrom: | 
        ${
          var freqs = inputs.freq.split(" ");
          return freqs;
         }
  diameter:
    type: float?
    doc: Diameter of the required beam
    inputBinding:
      prefix: --diameter
  coefficients_file:
    type: File?
    doc: Coefficients file name
    inputBinding:
      prefix: --coefficients-file
  coeff:
    type:
      type: enum
      symbols: [me, mh]
    doc: 'Which coefficients to use: mh for MeerKAT holography, me for MeerKAT EM
      simulation and vh for VLA holography?'
    inputBinding:
      prefix: --coeff
  output_eight:
    type: boolean?
    doc: Output complex volatge beams (8 files)
    inputBinding:
      prefix: --output-eight
  normalise:
    type: boolean?
    doc: normalise the E-Jones wrt central pixels
    inputBinding:
      prefix: --normalise

outputs:
  beam_list:
    type: File[]
    doc: Output complex volatge beams
    outputBinding:
      glob: '*.fits'
