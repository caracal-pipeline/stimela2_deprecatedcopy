cwlVersion: v1.1
class: CommandLineTool

requirements:
  DockerRequirement:
    dockerPull: stimela/meqtrees:1.2.4
  InlineJavascriptRequirement: {}
  InitialWorkDirRequirement:
    listing:
      - entry: $(inputs.msname)
        writable: true
      - entry: $(inputs.skymodel)
      - entry: $(inputs.config)
  InplaceUpdateRequirement:
    inplaceUpdate: true

baseCommand: python

arguments:
  - prefix: -c
    valueFrom: |
      import numpy
      import subprocess
      from pyrap.tables import table

      # JavaScript uses lowercase for bools
      true = True
      false = False
      null = None

      point_err = []
      msname = '$( inputs.msname.path )'
      rms_perr = $( inputs.pointing_accuracy )
      # Include pointing errors if needed
      if rms_perr:
          anttab = table(msname + '/' + 'ANTENNA')
          NANT = anttab.nrows()

          point_err.append('me.epe_enable=1')
          perr = numpy.random.randn(
              NANT)*rms_perr, numpy.random.randn(NANT)*rms_perr
          ll, mm = ' '.join(map(str, perr[0])), ' '.join(map(str, perr[-1]))
          point_err.append('oms_pointing_errors.pe_l.values_str={}'.format(ll))
          point_err.append('oms_pointing_errors.pe_m.values_str={}'.format(mm))

      base_command = 'meqtree-pipeliner.py'
      script_args = ['/usr/lib/python2.7/dist-packages/Cattery/Siamese/turbo-sim.py',
                     '=_simulate_MS']
      subprocess.check_call([base_command,
                             '--mt', '$( runtime.cores )',
                             '-c', '$( inputs.config.path )',
                             '[sim]',
                             'ms_sel.input_column=$( inputs.input_column )',
                             'ms_sel.field_index=$( inputs.field_index )',
                             'ms_sel.msname=$( inputs.msname.path )',
                             'me.use_smearing=$( inputs.use_smearing )',
                             'sim_mode=$( inputs.sim_mode )',
                             'noise_stddev=$( inputs.sefd /  Math.sqrt( 2 * inputs.dtime * inputs.dfreq ) )',
                             'ms_sel.ddid_index=$( inputs.ddid_index )',
                             'tiggerlsm.filename=$( inputs.skymodel.path )',
                             'ms_sel.output_column=$( inputs.output_column )',
                             'me.g_enable=$( inputs.gain_errors )',
                             'oms_gain_models.err-gain.error_model=SineError',
                             'oms_gain_models.err-gain.max_period=$( inputs.gainamp_max_period )',
                             'oms_gain_models.err-gain.min_period=$( inputs.gainamp_min_period )',
                             'oms_gain_models.err-gain.maxval=$( inputs.gainamp_max_error )',
                             'oms_gain_models.err-gain.minval=$( inputs.gainamp_min_error )',
                             'oms_gain_models.err-phase.error_model=SineError',
                             'oms_gain_models.err-phase.max_period=$( inputs.gainphase_max_period )',
                             'oms_gain_models.err-phase.min_period=$( inputs.gainphase_min_period )',
                             'oms_gain_models.err-phase.maxval=$( inputs.gainphase_max_error )',
                             'oms_gain_models.err-phase.minval=$( inputs.gainphase_min_error )']
                             + point_err + script_args)

inputs:
  msname:
    type: Directory

  config:
    type: File

  input_column:
    type: string?
    default: DATA

  output_column:
    type: string?
    default: CORRECTED_DATA

  field_index:
    type: int?
    default: 0

  tiggerskymodel:
    type: int?
    default: 1

  use_smearing:
    type: int?
    default: 0

  sim_mode:
    type: string?
    default: simulate

  sefd:
    type: float?
    default: 420.0

  dtime:
     type: float?
     default: 10

  dfreq:
      type: float?
      default: 770e6

  ddid_index:
    type: int?
    default: 0

  skymodel:
    type: File

  gain_errors:
    type: int?
    default: 0

  gainamp_max_period:
    type: float?
    default: 2
  
  gainamp_min_period:
    type: float?
    default: 1

  gainamp_max_error:
    type: float?
    default: 1.2

  gainamp_min_error:
    type: float?
    default: 0.8

  gainphase_max_period:
    type: float?
    default: 2
  
  gainphase_min_period:
    type: float?
    default: 1

  gainphase_max_error:
    type: float?
    default: 30

  gainphase_min_error:
    type: float?
    default: 5

  pointing_accuracy:
    type: float?
    default: 0

outputs:
   msname_out:
     type: Directory
     outputBinding:
       outputEval: $(inputs.msname)
