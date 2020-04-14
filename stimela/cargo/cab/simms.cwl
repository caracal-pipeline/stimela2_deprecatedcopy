cwlVersion: v1.1
class: CommandLineTool

baseCommand: simms

requirements:
  DockerRequirement:
    dockerImageId: stimela/simms:1.2.0
  InlineJavascriptRequirement: {}
  EnvVarRequirement:
    envDef:
      USER: root

inputs:
  msname:
    type: string?
    doc: Name out simulated MS file
    inputBinding:
      prefix: --name
  telescope:
    type: string
    inputBinding:
      prefix: --tel
  ra:
    type: string?
    doc: Phase tracking centre of observation
  dec:
    type: string?
    doc: Phase tracking centre of observation
  synthesis:
    type: float?
    doc: Synthesis time of observation
    inputBinding:
      prefix: --synthesis-time
  dtime:
    type: float?
    doc: Integration time
    inputBinding:
      prefix: --dtime
  freq0:
    type: float?
    doc: Start frequency of observation
    inputBinding:
      prefix: --freq0
  dfreq:
    type: float?
    doc: Channel width
    inputBinding:
      prefix: --dfreq
  nchan:
    type: int?
    doc: Number of channels
    inputBinding:
      prefix: --nchan
  direction:
    type: string?
    doc: Pointing direction. Example J2000,0h0m0s,-30d0m0d. Option --direction may
      be specified multiple times for multiple pointings. Provide a list of directions
      for multiple pointings; each pointing will have a unique field ID
    inputBinding:
      prefix: --direction
  antenna_file:
    type: File?
    doc: File that contains antenna coordinates
    inputBinding:
      prefix: --antenna-file
  type:
    type:
      type: enum
      symbols: [casa, ascii]
    doc: Type of antenna file
    inputBinding:
      prefix: --type
  coord_sys:
    type:
      type: enum
      symbols: [itrf, enu, wgs84]
    doc: Coordinate system of antenna coordinates in 'antenna-file'. Only needed if
      'type' is 'ascii'; CASA tables are assumed to be in ITRF coords
    inputBinding:
      prefix: --coord-sys
  lon_lat_elv:
    type: float[]?
    doc: Reference position of telescope. Comma seperated longitude,lattitude and
      elevation 'deg,deg,m'. Elevation is not crucial, lon,lat should be enough. If
      not specified, we'll try to get this info from the CASA database (assuming that
      your telescope is known to CASA)
    inputBinding:
      prefix: --lon-lat-elv
  noup:
    type: boolean?
    doc: Enable this to indicate that your ENU file does not have an 'up' dimension
    inputBinding:
      prefix: --noup
  scan_length:
    type: float?
    doc: Duration of a single scan in hours. Default is the entire observation (synthesis)
    inputBinding:
      prefix: --scan-length
  nband:
    type: int?
    doc: Number of subands
    inputBinding:
      prefix: --nband
  init_ha:
    type: float?
    doc: Initial hour angle. 'scan-length/2' is the default
    inputBinding:
      prefix: --init-ha
  pol:
    type: string?
    doc: polarization
    inputBinding:
      prefix: --pol
  feed:
    type: string?
    doc: Feed type
    inputBinding:
      prefix: --feed
  scan_lag:
    type: float?
    doc: Lag time between scans in hours
    inputBinding:
      prefix: --scan-lag
  set_limits:
    type: boolean?
    doc: Set telescope limits. Elevation and shadow limts. Works in tandem with 'shadow-limit,
      elevation-limit'
    inputBinding:
      prefix: --set-limits
  elevation_limit:
    type: float?
    doc: Dish elevation limit. Will only be taken into account if 'set-limits' is
      enabled.
    inputBinding:
      prefix: --elevation-limit
  shadow_limit:
    type: float?
    doc: Shadow limit. Will only be taken into account if 'set-limits' is enabled.
    inputBinding:
      prefix: --shadow-limit
  auto_correlations:
    type: boolean?
    doc: Don't flag autocorrelations
    inputBinding:
      prefix: --auto-correlations
  date:
    type: string?
    doc: 'Date of observation. Example UTC,2014/05/26 or UTC,2014/05/26/12:12:12 :
      default is today (format: EPOCH,yyyy/mm/dd/[h:m:s]'
    inputBinding:
      prefix: --date



outputs:
  msname_out:
    type: Directory
    outputBinding:
      glob: $(inputs.msname)
