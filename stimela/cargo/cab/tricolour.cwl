cwlVersion: v1.1
class: CommandLineTool

requirements:
  DockerRequirement:
    dockerPull: stimela/tricolour:1.2.5
  InlineJavascriptRequirement: {}
  InitialWorkDirRequirement:
    listing:
      - entry: $(inputs.ms)
        writable: true

baseCommand: /opt/code/dist/tricolourexe/tricolourexe

inputs:
  ms:
    type: Directory
    doc: MS to be flagged (single MS)
    inputBinding:
      position: 0
  config:
    type: File?
    doc: YAML config file containing parameters for the flagger in the 'sum_threshold'
      key.
    inputBinding:
      prefix: --config
  ignore_flags:
    type: boolean?
    doc: 'Ingnore existing flags'
    inputBinding:
      prefix: --ignore-flags
  flagging_strategy:
    type:
      type: enum
      symbols: [standard, polarisation, total_power]
    doc: Flagging Strategy. If 'standard' all correlations in the visibility are flagged
      independently. If 'polarisation' the polarised intensity sqrt(Q^2 + U^2 + V^2)
      is calculated and used to flag all correlations in the visibility
    inputBinding:
      prefix: --flagging-strategy
  row_chunks:
    type: int?
    doc: Hint indicating the number of Measurement Set rows to read in a single chunk.
      Smaller and larger numbers will tend to respectively decrease or increase both
      memory usage and computational efficiency
    inputBinding:
      prefix: --row-chunks
  baseline_chunks:
    type: int?
    doc: Number of baselines in a window chunk
    inputBinding:
      prefix: --baseline-chunks
  nworkers:
    type: int?
    doc: Number of workers (threads) to use. By default, set to twice the number of
      logical CPUs on the system. Many workers can also affect memory usage on systems
      with many cores.
    inputBinding:
      prefix: --nworkers
  dilate_masks:
    type: string?
    doc: Number of channels to dilate as int or string with units
    inputBinding:
      prefix: --dilate-masks
  data_column:
    type: string?
    doc: Name of visibility data column to flag
    inputBinding:
      prefix: --data-column
  scan_numbers:
    type: string?
    doc: Scan numbers to flag
    inputBinding:
      prefix: --scan-numbers
  subtract_model_column:
    type: string?
    doc: Columns to subtract from 'data-column' to form residuals to flag on
    inputBinding:
      prefix: --subtract-model-column
  field_names:
    type: string[]?
    doc: Name(s) of fields to flag. Defaults to flagging all
    inputBinding:
      valueFrom: |
        ${
          var fields = [];
          var field_names = inputs.field_names;
          for (var f in field_names) {
            fields.push("--field-names");
            fields.push(field_names[f]);
          }
          return fields;
        }
  disable_post_mortem:
    type: boolean?
    doc: Disable the default behaviour of starting the Interactive Python Debugger
      upon an unhandled exception. This may be necessary for batch pipelining
    inputBinding:
      prefix: --disable-post-mortem
  window_backend:
    type:
      type: enum
      symbols: [numpy, zarr-disk]
    doc: Visibility and flag data is re-ordered from a MS row ordering into time-frequency
      windows ordered by baseline. For smaller problems, it may be possible to pack
      a couple of scans worth of visibility data  into memory, but for larger problem
      sizes, it is necessary to reorder the data on disk
    inputBinding:
      prefix: --window-backend

outputs:
  msname_out:
    type: Directory
    doc: Output ms
    outputBinding:
      outputEval: $(inputs.ms)
