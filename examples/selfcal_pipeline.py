import stimela

PREFIX = "selfcal"
CASA_PREDICT = True
PRIMARY_BEAM = True
# Models to simulate lsm and/or fits
LSM = "point_skymodel.txt"
FITS = "selfcal-1-MFS-model.fits"
# Imaging params
NPIX = 256
CELL = "1asec"
NCHAN = 2

recipe = stimela.Recipe("selfcal_simulation",
                        indir="input",
                        outdir="output",
                        cachedir="cachedir")

recipe.add("simms", "makems", {
    "msname"               :   "meerkat_SourceRecovery.ms",
    "telescope"            :   "meerkat",
    "direction"            :   "J2000,0deg,-30deg",
    "synthesis"            :   0.5,      # in hours
    "dtime"                :   5,        # in seconds
    "freq0"                :   1.42e9,   # in hertz
    "dfreq"                :   1e6,      # in hertz
    "nchan"                :   4,
    },
    doc="Create Empty MS")

if PRIMARY_BEAM:
    recipe.add("eidos", "eidos", {
        "pixels": NPIX,
        "freq": "1418 1422 2",
        "diameter": 1.0,
        "coeff": 'me',
        "coefficients_file": "meerkat_beam_coeffs_em_zp_dct.npy",
        "output_eight": False,
       },
       doc='Generate primary beam images')

if not CASA_PREDICT:
    recipe.add("simulator", "simsky", {
        "msname"               :   recipe.makems.outputs["msname_out"],
        "config"               :   "tdlconf.profiles",
        "use_smearing"         :   False,
        "sefd"                 :   551,  # in Jy
        "output_column"        :   "DATA",
        "skymodel"             :   LSM
        },
        doc="Simulate sky model")

if CASA_PREDICT:
    recipe.add('casa_importfits', 'importfits', {
        "fitsimage": FITS,
        "imagename": FITS[:-5]+".im",
        "overwrite": True,
        },
        doc='Import fits to casa image')

    recipe.add('casa_ft', 'predict', {
        "vis": recipe.makems.outputs["msname_out"],
        "model": recipe.importfits.outputs["image_out"],
        "nterms": 1,
        "incremental": False,
        "usescratch": True,
        },
        doc='Predict vis from model')

    recipe.add("simulator", "add_data", {
        "msname"               :   recipe.predict.outputs["msname_out"],
        "config"               :   "tdlconf.profiles",
        "input_column"         :   "MODEL_DATA",
        "output_column"        :   "DATA",
        "sim_mode"             :   "add to MS",
        "sefd"                 :   551,  # in Jy
        "skymodel"             :   LSM
        },
        doc="Add predicted vis into data column with new model")

recipe.add("wsclean", "makeimage1", {
    "msname"               :   recipe.add_data.outputs["msname_out"],
    "name"                 :   PREFIX+"-1",
    "datacolumn"           :   "DATA",
    "save_source_list"     :   True,
    "fit_spectral_pol"     :   2,
    "channels_out"         :   NCHAN,
    "join_channels"        :   True,
    "mgain"                :   0.95,
    "scale"                :   CELL,
    "niter"                :   10000,
    "auto_threshold"       :   5,
    "size"                 :   [NPIX, NPIX]
    },
    doc="Image data")

recipe.add("pybdsf", "sourcefinder", {
    "filename"     :   recipe.makeimage1.outputs["restored_image_out"],
    "outfile"      :   "{}-catalog.fits".format(PREFIX),
    "format"       :   "fits",
    "thresh_isl"   :   20,
    "thresh_pix"   :   10,
    },
    doc="Source finding")


recipe.add("bdsf_fits2lsm", "convertfits", {
    "infile"             :   recipe.sourcefinder.outputs["model_out"],
    "phase_centre_image" :   recipe.makeimage1.outputs["restored_image_out"],
    "outfile"            :   "{}-catalog.lsm.html".format(PREFIX)
    },
    doc="Convert model catalog")

recipe.add("tigger_convert", "convertcatalog", {
    "input_skymodel"     :   recipe.convertfits.outputs["model_out"],
    "output_skymodel"    :   "{}-catalog_conv.lsm.html".format(PREFIX),
    "output_format"      :   "Tigger",
    "output_type"        :   "Tigger",
    "type"               :   "auto",
    "rename"             :   True,
    },
    doc="Convert model catalog")

recipe.add('cubical', "calibration", {
    "data_ms"              :   recipe.makeimage1.outputs["msname_out"],
    "data_column"          :   "DATA",
    "out_column"           :   "CORRECTED_DATA",
    "model_lsm"            :   recipe.convertcatalog.outputs["models_out"],
    "model_expression"     :   ["lsm_0"],
#    "model_column"         :   ['MODEL_DATA"], or use model column instead
#    "model_expression"     :   ["col_0"],
    "data_time_chunk"      :   24, #128,
    "data_freq_chunk"      :   12, #1024,
    "sel_ddid"             :   "0",
    "dist_ncpu"            :   16,
    "sol_jones"            :   "G",
    "sol_term_iters"       :   "50",
    "out_name"             :   PREFIX,
    "out_mode"             :   "ac",
    "weight_column"        :   "WEIGHT",
    "montblanc_dtype"      :   "float",
    "g_type"               :   "complex-2x2",
    "g_time_int"           :   16,
    "g_freq_int"           :   0,
    "g_save_to"            :   "{}_g-gains.parmdb".format(PREFIX),
    "bbc_save_to"          :   "{}_bbc-gains.parmdb".format(PREFIX),
    "g_clip_low"           :   0.5,
    "g_clip_high"          :   2.0,
    "madmax_enable"        :   True,
    "madmax_plot"          :   True,
    "madmax_threshold"     :   [0.0, 10.0],
    "madmax_estimate"      :   "corr",
    "out_plots"            :   True,
    "out_casa_gaintables"  :   True,
    "g_solvable"           :   True,
    "out_overwrite"        :   True,
    "log_boring"           :   True,
    "shared_memory"        :   4096,
    "montblanc_mem_budget" :   1024,
    },
    doc="Calibration")


recipe.add("wsclean", "makeimage2", {
    "msname"               :   recipe.calibration.outputs["msname_out"],
    "name"                 :   PREFIX+"-2",
    "datacolumn"           :   "CORRECTED_DATA",
    "save_source_list"     :   True,
    "scale"                :   "1asec",
    "fit_spectral_pol"     :   2,
    "channels_out"         :   NCHAN,
    "join_channels"        :   True,
    "mgain"                :   0.95,
    "scale"                :   CELL,
    "niter"                :   10000,
    "auto_threshold"       :   5,
    "size"                 :   [NPIX, NPIX]
    },
    doc="Image data")

recipe.add('fitstool', 'makecube1', {
    "image": recipe.makeimage2.outputs["restored_images_out"],
    "output": PREFIX+".cube.image.fits",
    "stack": True,
    "fits_axis": "FREQ",
    },
    doc='Make cube image')

recipe.add('sofia', 'sofia_mask', {
    "import_inFile": recipe.makecube1.outputs["image_out"],
    "steps_doFlag": False,
    "steps_doScaleNoise": True,
    "steps_doSCfind": True,
    "steps_doMerge": True,
    "steps_doReliability": False,
    "steps_doParameterise": True,
    "steps_doWriteMask": True,
    "steps_doMom0": False,
    "steps_doMom1": False,
    "steps_doWriteCat": True,
    "steps_doCubelets": False,
    "scaleNoise_statistic": 'mad',
    "SCfind_threshold": 5,
    "SCfind_rmsMode": 'mad',
    "merge_radiusX": 3,
    "merge_radiusY": 3,
    "merge_radiusZ": 3,
    "merge_minSizeX": 2,
    "merge_minSizeY": 2,
    "merge_minSizeZ": 2,
    "writeCat_basename": "sofia_mask",
    },
    doc='Make SoFiA mask')

recipe.add("crystalball", "transfermodel", {
    "ms": recipe.makeimage2.outputs["msname_out"],
    "sky_model": recipe.makeimage2.outputs["source_list"],
    "spectra": True,
    "row_chunks": 0,
    "model_chunks": 0,
    "points_only": False,
    "num_workers": 8
    },
    doc="Transfer Model")

recipe.collect_outputs([
                        "makems",
                        "makeimage1",
                        "sourcefinder",
                        "convertfits",
                        "convertcatalog",
                        "calibration",
                        "makeimage2",
                        "makecube1",
                        "sofia_mask",
                        "transfermodel"
                       ] + [
                        "importfits",
                        "predict",
                        "add_data"
                       ] if CASA_PREDICT else [
                        "simsky",
                       ] + [
                        "eidos"
                       ] if PRIMARY_BEAM else [
                       ])

recipe.run()
# To only generate the cwl files (<name>.cwl  <name>.yml)
#recipe.init()
