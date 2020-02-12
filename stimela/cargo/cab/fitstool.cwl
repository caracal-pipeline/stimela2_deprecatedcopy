cwlVersion: v1.1
class: CommandLineTool

requirements:
  DockerRequirement:
    dockerPull: stimela/meqtrees:1.2.0
  InlineJavascriptRequirement: {}
  InitialWorkDirRequirement: 
    listing:
      - entry: $(inputs.image)
  InplaceUpdateRequirement: 
    inplaceUpdate: true

baseCommand: fitstool.py

inputs:
  transfer:
    inputBinding:
      prefix: --transfer
    doc: transfer data from image 2 into image 1, preserving the FITS header of image 1
    type: boolean?
  add_axis:
    inputBinding:
      prefix: --add-axis
    doc: Add axis to a FITS image. The AXIS will be described by CTYPE:CRVAL:CRPIX:CDELT[:CUNIT:CROTA].
      The keywords in brackets are optinal, while those not in brackets are mendatory.
      This axis will be the last dimension.
    type: string?
  mean:
    inputBinding:
      prefix: --mean
    doc: take mean of input images
    type: boolean?
  stats:
    inputBinding:
      prefix: --stats
    doc: Print stats on images and exit. No output images will be written
    type: boolean?
  sanitize:
    inputBinding:
      prefix: --sanitize
    doc: Sanitize FITS files by replacing NANs and INFs with a vlaue
    type: float?
  header:
    inputBinding:
      prefix: --header
    doc: print header(s) of input image(s)
    type: boolean?
  image:
    doc: Input image(s)
    type: File[]
  edit_header:
    inputBinding:
      prefix: --edit-header
    doc: KEY=VALUE
    type: string?
  unstack_chunk:
    doc: Unstack FITS image into images of this width (along the given axis)
    type: int?
  rescale:
    inputBinding:
      prefix: --rescale
    doc: Rescale image values
    type: float?
  nonneg:
    inputBinding:
      prefix: --nonneg
    doc: replace negative values by 0
    type: boolean?
  delete_header:
    inputBinding:
      prefix: --delete-header
    doc: header key you wish to delete
    type: string?
  ratio:
    inputBinding:
      prefix: --ratio
    doc: take ratio of 2 input images
    type: boolean?
  diff:
    inputBinding:
      prefix: --diff
    doc: take difference of 2 input images
    type: boolean?
  fits_axis:
    doc: Stack/Unstack along this axis
    type: string?
  zero_to_nan:
    inputBinding:
      prefix: --zero-to-nan
    doc: Replace zeros with NaN
    type: boolean?
  reorder:
    inputBinding:
      prefix: --reorder
    doc: Required order. List of comma seperated indeces
    type: string?
  delete_files:
    inputBinding:
      prefix: --delete-files
    doc: Delete original file(s) after stacking/unstacking using --stack/--unstack
    type: boolean?
  sum:
    inputBinding:
      prefix: --sum
    doc: sum input images
    type: boolean?
  prod:
    inputBinding:
      prefix: --prod
    doc: product of input images
    type: boolean?
  force:
    inputBinding:
      prefix: --force
    doc: overwrite output file even if it exists
    type: boolean?
  zoom:
    inputBinding:
      prefix: --zoom
    doc: Zoom into central sqaure region given in pixles
    type: int?
  stack:
    inputBinding:
      prefix: --stack
      valueFrom: |
        ${
          var ims = inputs.image;
          var value = [inputs.output+":"+inputs.fits_axis];
          var location = runtime.outdir;
          for (var i in ims) {
            var image = location.concat("/".concat(ims[i].basename));
            value.push(image);
          }
          return value;
        }
    doc: Stack a list of FITS images along a given axis. This axis may given as an
      integer(as it appears in the NAXIS keyword), or as a string (as it appears in
      the CTYPE keyword)
    type: boolean?
  unstack:
    inputBinding:
      prefix: --unstack
      valueFrom: |
        ${
          var ims = inputs.image;
          var value = [inputs.output+":"+inputs.fits_axis+":"+inputs.unstack_chunk];
          var location = runtime.outdir;
          for (var i in ims) {
            var image = location.concat("/".concat(ims[i].basename));
            value.push(image);
          }
          return value;
        }
    doc: Unstack a FITS image into smaller chunks each having [each_chunk] planes
      along a given axis. This axis may given as an integer (as it appears in the
      NAXIS keyword), or as a string (as it appears in the CTYPE keyword)
    type: boolean?
  output:
    type: string
    doc: Output Image

outputs:
  images_out:
    type: File[]
    doc: Output Image
    outputBinding:
      glob: ${return inputs.output+'*'}
  image_out:
    type: File
    doc: Output Image
    outputBinding:
      glob: ${return inputs.output}
