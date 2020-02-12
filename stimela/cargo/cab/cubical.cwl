cwlVersion: v1.1
class: CommandLineTool

requirements:
  EnvVarRequirement:
    envDef:
      USER: root
  InlineJavascriptRequirement: {}
  InitialWorkDirRequirement:
    listing:
      - entry: $(inputs.data_ms)
        writable: true
      - entryname: model_lsm
        entry: "${ return {class: 'Directory', listing: inputs.model_lsm} }"
  InplaceUpdateRequirement:
    inplaceUpdate: true

baseCommand: docker

arguments: [run, -i,
            '--volume=${var path = runtime.outdir; return path.concat("/../../");}:${var path = runtime.outdir; return path.concat("/../../");}:rw',
            --volume=$(runtime.outdir):/working_directory:rw,
            --volume=$(runtime.tmpdir):/tmp:rw,
            --workdir=/working_directory,
            --user=1000:1000,
            '--shm-size=${var shm = "2048m";
                          var in_shm = inputs.shared_memory;
                          if (inputs.shared_memory) {
                              shm = in_shm.toString().concat("m");
                          }
                          return shm;
                         }',
            --rm, --env=TMPDIR=/tmp, --env=HOME=/working_directory, --env=USER=root,
            --cidfile=$(runtime.tmpdir)/20191115001729-761790.cid,
            stimela/cubical:dev,
            gocubical,
            --data-ms, '/working_directory/$(inputs.data_ms.basename)',
            --model-list, '${var models = "";
                             var map_order2model = {};
                             var lsms = inputs.model_lsm;
                             var columns = inputs.model_column;
                             var expressions = inputs.model_expression;
                             if (columns) {
                               for (var i in columns) {
                                 map_order2model["col_".concat(i)] = columns[i];
                               }
                             }
                             if (lsms) {
                               for (var i in lsms) {
                                 map_order2model["lsm_".concat(i)] = "/working_directory/model_lsm/".concat(lsms[i].basename);
                               }
                             }
                             for (var i in expressions) {
                               if (models) {
                                 models = models.concat(":".concat(expressions[i]));
                               } else {
                                 models = models.concat(expressions[i]);
                               }
                             }
                             for (var i in map_order2model) {
                               models = models.replace(new RegExp(i, "g"), map_order2model[i]);
                             }
                             return models;
                            }']

inputs:
  misc_parset_version:
    doc: "Parset version number, for migration purposes. Can't be specified on command\n\
      line."
    inputBinding:
      prefix: --misc-parset-version
    type: string?
  sol_term_iters:
    doc: "Number of iterations per Jones term. If empty, then each Jones\nterm is\
      \ solved for once, up to convergence, or up to its -max-iter\nsetting.\nOtherwise,\
      \ set to a list giving the number of iterations per Jones term.\nFor example,\
      \ given two Jones terms and --sol-num-iter 10,20,10, it will\ndo 10 iterations\
      \ on the first term, 20 on the second, and 10 again on the\nfirst."
    inputBinding:
      prefix: --sol-term-iters
    type: string?
  out_overwrite:
    doc: Allow overwriting of existing output files. If this is set, and the output
      parset file exists, will raise an exception
    inputBinding:
      prefix: --out-overwrite
      valueFrom: |
        ${
          var value = 0;
          var par_value = inputs.out_overwrite;
          if (par_value) {
            value=1;
          }
          return value;
        }
    type: boolean?
  sol_max_bl:
    doc: Max baseline length to solve for. If 0, no maximum is applied.
    inputBinding:
      prefix: --sol-max-bl
    type: float?
  data_ms:
    doc: Name of measurement set (MS)
    type: Directory
  debug_stop_before_solver:
    doc: Invoke pdb before entering the solver.
    inputBinding:
      prefix: --debug-stop-before-solver
      valueFrom: |
        ${
          var value = 0;
          var par_value = inputs.debug_stop_before_solver;
          if (par_value) {
            value=1;
          }
          return value;
        }
    type: boolean?
  dist_max_chunks:
    doc: Maximum number of time/freq data-chunks to load into memory simultaneously.
      If 0, then as many as possible will be loaded.
    inputBinding:
      prefix: --dist-max-chunks
    type: int?
  dist_min_chunks:
    doc: "Minimum number of time/freq data-chunks to load into memory\nsimultaneously.\
      \ This number should be divisible by ncpu-1 for optimal\nperformance."
    inputBinding:
      prefix: --dist-min-chunks
    type: string?
  out_model_column:
    doc: If set, model visibilities will be written to the specified column.
    inputBinding:
      prefix: --out-model-column
    type: string?
  data_chunk_by:
    doc: "If set, then time chunks will be broken up whenever the value in the named\n\
      column(s) jumps by >JUMPSIZE. Multiple column names may be given, separated\n\
      by commas. Use None to disable."
    inputBinding:
      prefix: --data-chunk-by
    type: string?
  flags_post_sol:
    doc: "If True, will do an extra round of flagging at the end  (post-solution)\n\
      \ based on solutions statistics, as per the following options."
    inputBinding:
      prefix: --flags-post-sol
      valueFrom: |
        ${
          var value = 0;
          var par_value = inputs.flags_post_sol;
          if (par_value) {
            value=1;
          }
          return value;
        }
    type: boolean?
  data_single_chunk:
    doc: "If set, processes just one chunk of data matching the chunk ID. Useful for\n\
      debugging."
    inputBinding:
      prefix: --data-single-chunk
    type: string?
  flags_time_density:
    doc: "Minimum percentage of unflagged visibilities along the time axis required\n\
      to prevent flagging."
    inputBinding:
      prefix: --flags-time-density
    type: string?
  data_time_chunk:
    doc: "Chunk data up by this number of timeslots. This limits the amount of data\n\
      processed at once. Smaller chunks allow for a smaller RAM footprint and\ngreater\
      \ parallelism, but this sets an upper limit on the solution intervals\nthat\
      \ may be employed. 0 means use full time axis."
    inputBinding:
      prefix: --data-time-chunk
    type: int?
  flags_save:
    doc: Save flags to named flagset in BITFLAG. If none or 0, will not save.
    inputBinding:
      prefix: --flags-save
    type: string?
  dist_ncpu:
    doc: Number of CPUs (processes) to use (0 or 1 disables parallelism).
    inputBinding:
      prefix: --dist-ncpu
    type: int?
  flags_chan_density:
    doc: "Minimum percentage of unflagged visibilities along the frequency axis\n\
      \ required to prevent flagging."
    inputBinding:
      prefix: --flags-chan-density
    type: string?
  sol_min_bl:
    doc: Min baseline length to solve for
    inputBinding:
      prefix: --sol-min-bl
    type: float?
  madmax_estimate:
    doc: MAD estimation mode. Use 'corr' for a separate estimate per each baseline
      and correlation. Otherwise, a single estimate per baseline is computed using
      'all' correlations, or only the 'diag' or 'offdiag' correlations.
    inputBinding:
      prefix: --madmax-estimate
    type:
      symbols: [corr, all, diag, offdiag]
      type: enum
  model_beam_l_axis:
    doc: Beam l axis
    inputBinding:
      prefix: --model-beam-l-axis
    type: string?
  montblanc_dtype:
    doc: Precision for simulation.
    inputBinding:
      prefix: --montblanc-dtype
    type: string?
  sel_chan:
    doc: "Channels to read (within each DDID). Default reads all. Can be specified\
      \ as\ne.g. \"5\", \"10~20\" (10 to 20 inclusive), \"10:21\" (same), \"10:\"\
      \ (from 10 to\nend), \":10\" (0 to 9 inclusive), \"~9\" (same)."
    inputBinding:
      prefix: --sel-chan
    type: string?
  debug_pdb:
    doc: Jumps into pdb on error.
    inputBinding:
      prefix: --debug-pdb
      valueFrom: |
        ${
          var value = 0;
          var par_value = inputs.debug_pdb;
          if (par_value) {
            value=1;
          }
          return value;
        }
    type: boolean?
  model_ddes:
    doc: "Enable direction-dependent models. If 'auto', this is determined\nby --sol-jones\
      \ and --model-list, otherwise, enable/disable\nexplicitly."
    inputBinding:
      prefix: --model-ddes
      valueFrom: |
        ${
          var value = 0;
          var par_value = inputs.model_ddes;
          if (par_value) {
            value=1;
          }
          return value;
        }
    type: boolean?
  dist_nworker:
    doc: Number of processes
    inputBinding:
      prefix: --dist-nworker
    type: int?
  montblanc_verbosity:
    doc: verbosity level of Montblanc's console output
    inputBinding:
      prefix: --montblanc-verbosity
    type: string?
  pin_main:
    doc: If set, pins the main process to a separate core. If set to, pins it to the  same
      core as the I/O process, if I/O process is pinned. Ignored if --dist-pin  is
      not set
    inputBinding:
      prefix: --pin-main
    type: string?
  dist_pin_io:
    doc: If not 0, pins the I/O & Montblanc process to a separate core, or cores if  --montblanc-threads
      is specified). Ignored if --dist-pin is not set
    inputBinding:
      prefix: --dist-pin-io
      valueFrom: |
        ${
          var value = 0;
          var par_value = inputs.dist_pin_io;
          if (par_value) {
            value=1;
          }
          return value;
        }
    type: boolean?
  flags_apply:
    doc: "Which flagsets will be applied prior to calibration. \nUse \"-FLAGSET\"\
      \ to apply everything except the named flagset (\"-cubical\" is\nuseful, to\
      \ ignore the flags of a previous CubiCal run)."
    inputBinding:
      prefix: --flags-apply
    type: string?
  log_verbose:
    doc: Default console output verbosity level
    inputBinding:
      prefix: --log-verbose
    type: string?
  model_beam_m_axis:
    doc: Beam m axis
    inputBinding:
      prefix: --model-beam-m-axis
    type: string?
  sol_delta_g:
    doc: "Theshold for gain accuracy - gains which improve by less than this value\n\
      are considered converged."
    inputBinding:
      prefix: --sol-delta-g
    type: string?
  sol_subset:
    doc: "Additional subset of data to actually solve for. Any TaQL string may be\n\
      used."
    inputBinding:
      prefix: --sol-subset
    type: string?
  sel_taql:
    doc: Additional TaQL selection string. Combined with other selection options.
    inputBinding:
      prefix: --sel-taql
    type: string?
  out_column:
    doc: Output MS column name (if applicable).
    inputBinding:
      prefix: --out-column
    type: string?
  log_memory:
    doc: Log memory usage.
    inputBinding:
      prefix: --log-memory
      valueFrom: |
        ${
          var value = 0;
          var par_value = inputs.log_memory;
          if (par_value) {
            value=1;
          }
          return value;
        }
    type: boolean?
  log_file_verbose:
    doc: "Default logfile output verbosity level. \nCan either be a single number,\
      \ or a sequence of \"name=level,name=level,...\"\nassignments. If None, then\
      \ this simply follows the console level."
    inputBinding:
      prefix: --log-file-verbose
    type: string?
  data_column:
    doc: Name of MS column to read for data.
    inputBinding:
      prefix: --data-column
    type: string?
  montblanc_mem_budget:
    doc: Memory budget in MB for simulation.
    inputBinding:
      prefix: --montblanc-mem-budget
    type: int?
  out_subtract_dirs:
    doc: "Which model directions to subtract, if generating residuals. \":\"\nsubtracts\
      \ all. Can also be specified as \"N\", \"N:M\", \":N\", \"N:\", \"N,M,K\"."
    inputBinding:
      prefix: --out-subtract-dirs
    type: int?
  sol_jones:
    doc: "Comma-separated list of Jones terms to enable, e.g. \"G,B,dE\"\n(default:\
      \ G)"
    inputBinding:
      prefix: --sol-jones
    type: string?
  out_mode:
    doc: "Operational mode.\n[so] solve only;\n[sc] solve and generate corrected visibilities;\n\
      [sr] solve and generate corrected residuals;\n[ss] solve and generate uncorrected\
      \ residuals;\n[ac] apply solutions, generate corrected visibilities;\n[ar] apply\
      \ solutions, generate corrected residuals;\n[as] apply solutions, generate uncorrected\
      \ residuals;"
    inputBinding:
      prefix: --out-mode
    type:
      symbols: [so, sc, sr, ss, ac, ar, as]
      type: enum
  sol_precision:
    doc: Solve in single or double precision
    inputBinding:
      prefix: --sol-precision
    type: string?
  out_subtract_model:
    doc: Which model to subtract, if generating residuals.
    inputBinding:
      prefix: --out-subtract-model
    type: int?
  misc_random_seed:
    doc: "Seed random number generator with explicit seed. Useful for reproducibility\n\
      of the random-based optimizations (sparsification, etc.)."
    inputBinding:
      prefix: --misc-random-seed
    type: string?
  out_plots:
    doc: Generate summary plots.
    inputBinding:
      prefix: --out-plots
      valueFrom: |
        ${
          var value = 0;
          var par_value = inputs.out_plots;
          if (par_value) {
            value=1;
          }
          return value;
        }
    type: boolean?
  madmax_diag:
    doc: Flag on on-diagonal (parallel-hand) residuals
    inputBinding:
      prefix: --madmax-diag
      valueFrom: |
        ${
          var value = 0;
          var par_value = inputs.madmax_diag;
          if (par_value) {
            value=1;
          }
          return value;
        }
    type: boolean?
  log_append:
    doc: Append to log file if it exists.
    inputBinding:
      prefix: --log-append
      valueFrom: |
        ${
          var value = 0;
          var par_value = inputs.log_append;
          if (par_value) {
            value=1;
          }
          return value;
        }
    type: boolean?
  madmax_plot:
    doc: Enable plots for Mad Max flagging. Use 'show' to show figures interactively.
      Plots will show the worst flagged baseline, and a median flagged baseline, provided
      the fraction of flagged visibilities is above --flags-mad-plot-thr.
    inputBinding:
      prefix: --madmax-plot
      valueFrom: |
        ${
          var value = 0;
          var par_value = inputs.madmax_plot;
          if (par_value) {
            value=1;
          }
          return value;
        }
    type: boolean?
  sol_delta_chi:
    doc: "Theshold for solution stagnancy - if the chi-squared is improving by less\n\
      than this value, the gain is considered stalled."
    inputBinding:
      prefix: --sol-delta-chi
    type: string?
  flags_tf_chisq_median:
    doc: "Intervals with chi-squared values larger than this value times the median\n\
      will be flagged."
    inputBinding:
      prefix: --flags-tf-chisq-median
    type: string?
  flags_auto_init:
    doc: "Insert BITFLAG column if it is missing, and initialize a named flagset\n\
      from FLAG/FLAG_ROW."
    inputBinding:
      prefix: --flags-auto-init
    type: string?
  flags_tf_np_median:
    doc: "Minimum percentage of unflagged visibilities per time/frequncy slot\nrequired\
      \ to prevent flagging."
    inputBinding:
      prefix: --flags-tf-np-median
    type: string?
  madmax_plot_frac_above:
    doc: Threshold (in terms of fraction of visibilities flagged) above which plots
      will be generated.
    inputBinding:
      prefix: --madmax-plot-frac-above
    type: float?
  data_freq_chunk:
    doc: "Chunk data by this number of channels. See time-chunk for info.\n0 means\
      \ full frequency axis."
    inputBinding:
      prefix: --data-freq-chunk
    type: int?
  montblanc_device_type:
    doc: Use CPU or GPU for simulation.
    inputBinding:
      prefix: --montblanc-device-type
    type: string?
  sel_ddid:
    doc: "DATA_DESC_IDs to read from the MS. Default reads all. Can be specified as\n\
      e.g. \"5\", \"5,6,7\", \"5~7\" (inclusive range), \"5:8\" (exclusive range),\n\
      \"5:\" (from 5 to last)."
    inputBinding:
      prefix: --sel-ddid
    type: string?
  dist_pin:
    doc: If empty or None, processes will not be pinned to cores. Otherwise, set to
      the starting core number, or 'N:K' to start with N and step by K
    inputBinding:
      prefix: --dist-pin
    type: int?
  log_boring:
    doc: Disable progress bars and some console output.
    inputBinding:
      prefix: --log-boring
      valueFrom: |
        ${
          var value = 0;
          var par_value = inputs.log_boring;
          if (par_value) {
            value=1;
          }
          return value;
        }
    type: boolean?
  flags_reinit_bitflags:
    doc: "If true, reninitializes BITFLAG column from scratch. Useful if you ended\
      \ up\nwith a dead one."
    inputBinding:
      prefix: --flags-reinit-bitflags
      valueFrom: |
        ${
          var value = 0;
          var par_value = inputs.flags_reinit_bitflags;
          if (par_value) {
            value=1;
          }
          return value;
        }
    type: boolean?
  dist_nthread:
    doc: 'Number of OMP threads to use. 0: determine automatically.'
    inputBinding:
      prefix: --dist-nthread
    type: int?
  sel_field:
    doc: FIELD_ID to read from the MS.
    inputBinding:
      prefix: --sel-field
    type: int?
  sel_diag:
    doc: If true, then data, model and gains are taken to be diagonal. Off-diagonal
      terms in data and model are ignored. This option is then enforced on all Jones
      terms.
    inputBinding:
      prefix: --sel-diag
      valueFrom: |
        ${
          var value = 0;
          var par_value = inputs.sel_diag;
          if (par_value) {
            value=1;
          }
          return value;
        }
    type: boolean?
  sol_chi_int:
    doc: "Number of iterations to perform between chi-suqared checks. This is done\
      \ to\navoid computing the expensive chi-squared test evey iteration."
    inputBinding:
      prefix: --sol-chi-int
    type: string?
  weight_column:
    doc: "Column to read weights from. Weights are applied by default. Specify an\n\
      empty string to disable."
    inputBinding:
      prefix: --weight-column
    type: string?
  montblanc_feed_type:
    doc: Simulate using linear or circular feeds.
    inputBinding:
      prefix: --montblanc-feed-type
    type: string?
  debug_panic_amplitude:
    doc: "Throw an error if a visibility amplitude in the results exceeds the given\
      \ value.\nUseful for troubleshooting."
    inputBinding:
      prefix: --debug-panic-amplitude
    type: float?
  data_chunk_by_jump:
    doc: "The jump size used in conjunction with chunk-by. If 0, then any change in\n\
      value is a jump. If n, then the change must be >n."
    inputBinding:
      prefix: --data-chunk-by-jump
    type: float?
  out_reinit_column:
    doc: "Reinitialize output MS column. Useful if the column is in a half-filled\n\
      or corrupt state."
    inputBinding:
      prefix: --out-reinit-column
      valueFrom: |
        ${
          var value = 0;
          var par_value = inputs.out_reinit_column;
          if (par_value) {
            value=1;
          }
          return value;
        }
    type: boolean?
  madmax_threshold:
    doc: 'Threshold for MAD flagging per baseline (specified in sigmas). Residuals
      exceeding mad-thr*MAD/1.428 will be flagged. MAD is computed per baseline. This
      can be specified as a list e.g. N1,N2,N3,... The first value is used to flag
      residuals before a solution starts (use 0 to disable), the next value is used
      when the residuals are first recomputed during the solution several iteratins
      later (see -chi-int), etc. A final pass may be done at the end of the solution.
      The last value in the list is reused if necessary. Using a list with gradually
      decreasing values may be sensible. #metavar:SIGMAS'
    inputBinding:
      prefix: --madmax-threshold
      itemSeparator: ','
    type: float[]?
  madmax_global_threshold:
    doc: Threshold for global median MAD (MMAD) flagging. MMAD is computed as the
      median of the per-baseline MADs. Residuals exceeding S*MMAD/1.428 will be flagged.
      Can be specified
    inputBinding:
      prefix: --madmax-global-threshold
    type: float[]?
  out_casa_gaintables:
    doc: Export gaintables to CASA caltable format. Tables are exported to same directory
      as set for cubical databases
    inputBinding:
      prefix: --out-casa-gaintables
      valueFrom: |
        ${
          var value = 0;
          var par_value = inputs.out_casa_gaintables;
          if (par_value) {
            value=1;
          }
          return value;
        }
    type: boolean?
  madmax_enable:
    doc: Enable Mad Max flagging in the solver. This computes the median absolute
      residual (i.e. median absolute deviation from zero), and flags visibilities
      exceeding the thresholds
    inputBinding:
      prefix: --madmax-enable
      valueFrom: |
        ${
          var value = 0;
          var par_value = inputs.madmax_enable;
          if (par_value) {
            value=1;
          }
          return value;
        }
    type: boolean?
  model_list:
    doc: Predict model visibilities from given LSM (using Montblanc).
    type: string[]?
  model_beam_pattern:
    doc: "Apply beams if specified eg. 'beam_$(corr)_$(reim).fits' or\n'beam_$(CORR)_$(REIM).fits'"
    inputBinding:
      prefix: --model-beam-pattern
    type: File?
  flags_ddid_density:
    doc: "Minimum percentage of unflagged visibilities along the DDID axis\nrequired\
      \ to prevent flagging."
    inputBinding:
      prefix: --flags-ddid-density
    type: string?
  sol_stall_quorum:
    doc: "Minimum percentage of solutions which must have stalled before terminating\n\
      the solver."
    inputBinding:
      prefix: --sol-stall-quorum
    type: float?
  sol_last_rites:
    doc: "Re-estimate chi-squred and noise at the end of a solution cycle. Disabling\n\
      last rites can save a bit of time, but makes the post-solution stats less\n\
      informative."
    inputBinding:
      prefix: --sol-last-rites
      valueFrom: |
        ${
          var value = 0;
          var par_value = inputs.sol_last_rites;
          if (par_value) {
            value=1;
          }
          return value;
        }
    type: boolean?
  madmax_offdiag:
    doc: Flag on off-diagonal (cross-hand) residuals
    inputBinding:
      prefix: --madmax-offdiag
      valueFrom: |
        ${
          var value = 0;
          var par_value = inputs.madmax_offdiag;
          if (par_value) {
            value=1;
          }
          return value;
        }
    type: boolean?
  out_name:
    doc: Base name of output files.
    inputBinding:
      prefix: --out-name
    type: string?
  model_lsm:
    doc: List of lsm models
    type: File[]?
  model_column:
    doc: List of MODEL data columns
    type: string[]?
  model_order:
    doc: 'Order of the model used for calibration. .e.g. [lsm_0, lsm_1, col_0] NB:
      Only use either lsm_<index> or col_<index>'
    type: string[]?
  model_expression:
    doc: Model expressions to pass to cubical. Only use either lsm_<index> or col_<index>.
      This can also include dd tagged models using '@de' e.g. ['lsm_0@de+-lsm_1',
      'col_0']
    type: string[]
  shared_memory:
    doc: Memory shared between processes
    type: int?
  bbc_plot:
    doc: Generate output BBC plots.
    inputBinding:
      prefix: --bbc-plot
      valueFrom: |
        ${
          var value = 0;
          var par_value = inputs.bbc_plot;
          if (par_value) {
            value=1;
          }
          return value;
        }
    type: boolean?
  bbc_load_from:
    doc: "Load and apply BBCs computed in a previous run. Apply with care! This will\n\
      \ tend to suppress all unmodelled flux towards the centre of the field."
    inputBinding:
      prefix: --bbc-load-from
    type: File?
  bbc_apply_2x2:
    doc: "Apply full 2x2 BBCs (as opposed to diagonal-only). Only enable this if you\n\
      really trust the polarisation information in your sky model."
    inputBinding:
      prefix: --bbc-apply-2x2
      valueFrom: |
        ${
          var value = 0;
          var par_value = inputs.bbc_apply_2x2;
          if (par_value) {
            value=1;
          }
          return value;
        }
    type: boolean?
  bbc_per_chan:
    doc: Compute BBCs per-channel (else across entire band).
    inputBinding:
      prefix: --bbc-per-chan
      valueFrom: |
        ${
          var value = 0;
          var par_value = inputs.bbc_per_chan;
          if (par_value) {
            value=1;
          }
          return value;
        }
    type: boolean?
  bbc_save_to:
    doc: "Compute suggested BBCs at end of run,\n\
      \ and save them to the given database.\
      \ It can be useful to have this always\n\
      \ enabled, since the BBCs provide useful diagnostics\
      \ of the solution quality\n(and are not actually\
      \ applied without a load-from setting)."
    inputBinding:
      prefix: --bbc-save-to
    type: string
  bbc_compute_2x2:
    doc: "Compute full 2x2 BBCs (as opposed to diagonal-only). Only useful if you\n\
      really trust the polarisation information in your sky model."
    inputBinding:
      prefix: --bbc-compute-2x2
      valueFrom: |
        ${
          var value = 0;
          var par_value = inputs.bbc_compute_2x2;
          if (par_value) {
            value=1;
          }
          return value;
        }
    type: boolean?

outputs:
  parmdb_save_out:
    type: File[]
    outputBinding:
      glob: '*parmdb'
  msname_out:
    type: Directory
    outputBinding:
      outputEval: $(inputs.data_ms)
  plot_out:
    type: Directory
    outputBinding:
      glob: cubical.cc-out
  casa_plot_out:
    type: Directory[]?
    outputBinding:
      glob: '*.casa'
