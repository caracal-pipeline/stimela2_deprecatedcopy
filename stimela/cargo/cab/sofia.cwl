cwlVersion: v1.1
class: CommandLineTool

requirements:
  DockerRequirement:
    dockerPull: stimela/sofia:1.2.0
  InlineJavascriptRequirement: {}
  InitialWorkDirRequirement:
    listing:
      - entry: $(inputs.import_inFile)
      - entryname: ${ return inputs.writeCat_basename + ".txt" }
        entry: |-
          ${
             var dump = "";
             for (var key in inputs) {
               var param=key;
               param=param.replace("_", ".");
               var value=inputs[key];
               if (value) {
                 if (param=="import.inFile") {
                   var path = runtime.outdir;
                   value = path.concat("/".concat(value["basename"]));
                 }
                 var entry=param.concat("=".concat(value));
                 dump=dump.concat(entry.concat("\r\n"));
               }
             }
             return dump;
          }
        writable: true
  InplaceUpdateRequirement:
    inplaceUpdate: true

baseCommand: sofia_pipeline.py

arguments: ['${return inputs.writeCat_basename + ".txt"}']

inputs:
  import_inFile:
    type: File?
    doc:

  parameters_dilateThreshold:
    type: float?
    doc:

  import_sources:
    type: string[]?
    doc:

  threshold_threshold:
    type: float?
    doc:

  scaleNoise_interpolation:
    type:
      - "null"
      - type: enum
        symbols: [none, linear, cubic]
    doc:

  merge_radiusY:
    type: int?
    doc:

  steps_doDebug:
    type: boolean?
    doc:

  merge_radiusX:
    type: int?
    doc:

  SCfind_edgeMode:
    type: string?
    doc:

  reliability_threshold:
    type: float?
    doc:

  steps_doFilterArtefacts:
    type: boolean?
    doc:

  steps_doSubcube:
    type: boolean?
    doc:

  scaleNoise_method:
    type:
      - "null"
      - type: enum
        symbols: [global, local]
    doc:

  steps_doMerge:
    type: boolean?
    doc:

  reliability_scaleKernel:
    type: float?
    doc:

  optical_storeMultiCat:
    type: boolean?
    doc:

  reliability_negPerBin:
    type: float?
    doc:

  steps_doSCfind:
    type: boolean?
    doc:

  smooth_kernelY:
    type: float?
    doc:

  import_weightsFile:
    type: File?
    doc:

  SCfind_maskScaleZ:
    type: float?
    doc:

  scaleNoise_statistic:
    type: string?
    doc:

  threshold_clipMethod:
    type: string?
    doc:

  steps_doCNHI:
    type: boolean?
    doc:

  threshold_fluxRange:
    type:
      - "null"
      - type: enum
        symbols: [positive, negative, all]
    doc:

  SCfind_sizeFilter:
    type: float?
    doc:

  smooth_edgeMode:
    type: string?
    doc:

  wavelet_iterations:
    type: int?
    doc:

  merge_maxVoxels:
    type: int?
    doc:

  import_weightsFunction:
    type: string?
    doc:

  threshold_rmsMode:
    type: string?
    doc:

  writeCat_writeASCII:
    type: boolean?
    doc:

  import_subcubeMode:
    type: string?
    doc:

  CNHI_verbose:
    type: int?
    doc:

  flag_file:
    type: File?
    doc:

  smooth_kernelX:
    type: float?
    doc:

  reliability_usecov:
    type: boolean?
    doc:

  merge_maxLoS:
    type: int?
    doc:

  steps_doCubelets:
    type: boolean?
    doc:

  CNHI_medianTest:
    type: boolean?
    doc:

  merge_maxFill:
    type: int?
    doc:

  steps_doWriteFilteredCube:
    type: boolean?
    doc:

  scaleNoise_gridSpatial:
    type: int?
    inputBinding:
      prefix: --scaleNoise.gridSpatial=
      separate: false
    doc:

  SCfind_threshold:
    type: float?
    doc:

  merge_radiusZ:
    type: int?
    doc:

  SCfind_verbose:
    type: boolean?
    doc:

  scaleNoise_scaleY:
    type: boolean?
    doc:

  scaleNoise_edgeZ:
    type: int?
    doc:

  SCfind_kernelUnit:
    type: string?
    doc:

  scaleNoise_scaleZ:
    type: boolean?
    doc:

  writeCat_writeXML:
    type: boolean?
    doc:

  writeCat_overwrite:
    type: boolean?
    doc:

  steps_doThreshold:
    type: boolean?
    doc:

  merge_minIntens:
    type: float?
    doc:

  writeCat_basename:
    type: string?
    doc:

  scaleNoise_edgeY:
    type: int?
    doc:

  steps_doFlag:
    type: boolean?
    doc:

  merge_positivity:
    type: boolean?
    doc:

  scaleNoise_windowSpectral:
    type: int?
    doc:

  writeCat_writeSQL:
    type: boolean?
    doc:

  CNHI_qReq:
    type: float?
    doc:

  threshold_verbose:
    type: boolean?
    doc:

  scaleNoise_scaleX:
    type: boolean?
    doc:

  wavelet_scaleZ:
    type: int?

  CNHI_minScale:
    type: int?
    doc:

  steps_doWriteNoiseCube:
    type: boolean?
    doc:

  scaleNoise_fluxRange:
    type:
      - "null"
      - type: enum
        symbols: [positive, negative, all]
    doc:

  wavelet_scaleXY:
    type: int?
    doc:

  merge_maxIntens:
    type: float?
    doc: Maximum Intensity

  SCfind_kernels:
    type: int[]?
    doc: Kernels

  optical_spatSize:
    type: float?
    doc: spat size

  smooth_kernel:
    type: string?
    doc: Smooth Kernel

  writeCat_parameters:
    type: string[]?
    doc: Write catalog parameters

  pipeline_trackMemory:
    type: boolean?
    doc:

  reliability_fMin:
    type: float?
    doc: Reliability flux

  parameters_dilateMask:
    type: boolean?
    doc: Dilate mask

  flag_regions:
    type: string[]?
    doc:

  reliability_parSpace:
    type: string[]?
    doc:

  filterArtefacts_threshold:
    type: float?
    doc:

  reliability_skellamTol:
    type: float?
    doc:

  import_maskFile:
    type: File?
    doc:

  steps_doScaleNoise:
    type: boolean?
    doc:

  steps_doReliability:
    type: boolean?
    doc:

  steps_doWavelet:
    type: boolean?
    doc:

  reliability_makePlot:
    type: boolean?
    doc:

  steps_doWriteMask:
    type: boolean?
    doc:

  SCfind_rmsMode:
    type: string?
    doc:

  parameters_fitBusyFunction:
    type: boolean?
    doc:

  merge_minSizeX:
    type: int?
    doc:

  steps_doOptical:
    type: boolean?
    doc:

  merge_minFill:
    type: int?
    doc:

  scaleNoise_windowSpatial:
    type: int?
    doc:

  CNHI_maxScale:
    type: int?
    doc:

  steps_doMom1:
    type: boolean?
    doc:

  reliability_kernel:
    type: float[]?
    doc:

  merge_minSizeZ:
    type: int?
    doc:

  steps_doWriteCat:
    type: boolean?
    doc:

  steps_doSmooth:
    type: boolean?
    doc:

  wavelet_positivity:
    type: boolean?
    doc:

  parameters_dilateChanMax:
    type: int?
    doc:

  parameters_dilatePixMax:
    type: int?
    doc:

  parameters_optimiseMask:
    type: boolean?
    doc:

  merge_maxSizeZ:
    type: int?
    doc:

  smooth_kernelZ:
    type: float?
    doc:

  optical_specSize:
    type: float?
    doc:

  filterArtefacts_dilation:
    type: int?
    doc:

  SCfind_fluxRange:
    type:
      - "null"
      - type: enum
        symbols: [positive, negative, all]
    doc:

  optical_sourceCatalogue:
    type: File?
    doc:

  parameters_getUncertainties:
    type: boolean?
    doc:

  SCfind_maskScaleXY:
    type: float?
    doc:

  reliability_logPars:
    type: int[]?
    doc:

  steps_doParameterise:
    type: boolean?
    doc:

  merge_maxSizeY:
    type: int?
    doc:

  CNHI_pReq:
    type: float?
    doc:

  wavelet_threshold:
    type: float?
    doc:

  writeCat_compress:
    type: boolean?
    doc:

  merge_minVoxels:
    type: int?

  scaleNoise_edgeX:
    type: int?

  scaleNoise_gridSpectral:
    type: int?

  import_subcube:
    type: string[]?

  import_invertData:
    type: boolean?

  merge_minSizeY:
    type: int?

  reliability_autoKernel:
    type: boolean?

  steps_doMom0:
    type: boolean?

  merge_minLoS:
    type: int?

  merge_maxSizeX:
    type: int?

  pipeline_pedantic:
    type: boolean?

outputs:
  writeOutCat:
    type: File?
    outputBinding:
      glob: '*txt'

  writeOutAscii:
    type: File?
    outputBinding:
      glob: '*cat.ascii'

  writeOutMask:
    type: File?
    outputBinding:
      glob: '*mask.fits'

  writeOutMom0:
    type: File?
    outputBinding:
      glob: '*mom0.fits'

  writeOutMom1:
    type: File?
    outputBinding:
      glob: '*mom1.fits'

  writeOutNrch:
    type: File?
    outputBinding:
      glob: '*nrch.fits'

  writeOutCubelets:
    type: Directory?
    outputBinding:
      glob: '*cubelets'
