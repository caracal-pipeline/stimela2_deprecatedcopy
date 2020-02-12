import os
import re
import sys
import time
import inspect
import logging
import warnings
import tempfile
import subprocess

from stimela.RecipeStep import Step
from stimela.RecipeCWL import Workflow

import ruamel.yaml as yaml
from ruamel.yaml.comments import CommentedMap as ordereddict

CWLDIR = os.path.join(os.path.dirname(__file__), "cargo/cab")
TMPLT = {'ref_ant': ordereddict([('doc', 'Reference antenna - its phase is guaranteed to be zero.'),
                                 ('inputBinding', ordereddict([('prefix', 'ref-ant')])),
                                 ('type', 'string?')]),
         'time_int': ordereddict([('doc', 'Time solution interval for this term. 0 means use entire chunk.'),
                                  ('inputBinding', ordereddict([('prefix', 'time-int')])),
                                  ('type', 'float?')]),
         'freq_int': ordereddict([('doc', 'Frequency solution interval for this term. 0 means use entire chunk.'),
                                  ('inputBinding', ordereddict([('prefix', 'freq-int')])), ('type', 'float?')]),
         'update_type': ordereddict([('doc', "Determines update type. This does not change the Jones solver type, but"\
                                      "restricts the update rule to pin the solutions within a certain subspace:"\
                                      "'full' is the default behaviour;'diag' pins the off-diagonal terms to 0;"\
                                      "'phase-diag' also pins the amplitudes of the diagonal terms to unity;"\
                                      "'amp-diag' also pins the phases to 0."),
                                     ('inputBinding', ordereddict([('prefix', 'update-type')])),
                                     ('type', 'string?')]),
         'fix_dirs': ordereddict([('doc', 'For DD terms, makes the listed directions non-solvable.'),
                                  ('inputBinding', ordereddict([('prefix', 'fix-dirs')])),
                                  ('type', 'int?')]),
         'max_iter': ordereddict([('doc', 'Maximum number of iterations spent on this term.'),
                                  ('inputBinding', ordereddict([('prefix', 'max-iter')])),
                                  ('type', 'int?')]),
         'clip_high': ordereddict([('doc', 'Amplitude clipping - flag solutions with any amplitudes above this value.'),
                                   ('inputBinding', ordereddict([('prefix', 'clip-high')])),
                                   ('type', 'float?')]),
         'xfer_from': ordereddict([('doc', 'Transfer solutions from given database. Similar to -load-from, but'\
                                    'solutions will be interpolated onto the required time/frequency grid,'\
                                    'so they can originate from a different field (e.g. from a calibrator).'),
                                   ('inputBinding', ordereddict([('prefix', 'xfer-from')])),
                                   ('type', 'File?')]),
         'dd_term': ordereddict([('doc', 'Determines whether this term is direction dependent. --model-ddes must'),
                                 ('inputBinding', ordereddict([('prefix', 'dd-term'),
                                 ('valueFrom', '${\n  var value = 0;\n  var par_value = inputs.g1_dd_term;\n'
                                  '  if (par_value) {\n    value=1;\n  }\n  return value;\n}\n')])),
                                 ('type', 'boolean?')]),
         'load_from': ordereddict([('doc', 'Load solutions from given database. The DB must define solutions '\
                                    'on the same time/frequency grid (i.e. should normally come from '\
                                    'calibrating the same pointing/observation). By default, the Jones '\
                                    'matrix label is used to form up parameter names, but his may be '\
                                    'overridden by adding an explicit "//LABEL" to the database filename.'),
                                   ('inputBinding', ordereddict([('prefix', 'load-from')])),
                                   ('type', 'File?')]),
         'prop_flags': ordereddict([('doc', "Flag propagation policy. Determines how flags raised on gains propagate back "\
                                     "into the data. Options are 'never' to never propagate, 'always' to always propagate, "\
                                     "'default' to only propagate flags from direction-independent gains."),
                                    ('inputBinding', ordereddict([('prefix', 'prop-flags')])), ('type', 'string?')]),
         'clip_after': ordereddict([('doc', 'Number of iterations after which to clip this gain.'),
                                    ('inputBinding', ordereddict([('prefix', 'clip-after')])),
                                    ('type', 'int?')]),
         'conv_quorum': ordereddict([('doc', 'Minimum percentage of converged solutions to accept.'),
                                     ('inputBinding', ordereddict([('prefix', 'conv-quorum')])),
                                     ('type', 'float?')]),
         'solvable': ordereddict([('doc', 'Set to 0 (and specify -load-from or -xfer-from) to load a non-solvable '\
                                   'term is loaded from disk. Not to be confused with --sol-jones, which determines '\
                                   'the active Jones terms.'),
                                  ('inputBinding', ordereddict([('prefix', 'solvable'),
                                  ('valueFrom', '${\n  var value = 0;\n  var par_value = inputs.g1_solvable;\n  '\
                                   'if (par_value) {\n    value=1;\n  }\n  return value;\n}\n')])),
                                  ('type', 'boolean?')]),
         'max_prior_error': ordereddict([('doc', 'Flag solution intervals where the prior error estimate is above this value.'),
                                         ('inputBinding', ordereddict([('prefix', 'max-prior-error')])),
                                         ('type', 'float?')]),
         'type': ordereddict([('doc', 'Type of Jones matrix to solve for. Note that if multiple Jones terms are '\
                               'enabled, then only complex-2x2 is supported.'),
                              ('inputBinding', ordereddict([('prefix', 'type')])),
                              ('type', 'string?')]),
         'max_post_error': ordereddict([('doc', 'Flag solution intervals where the posterior variance estimate is above this value.'),
                                        ('inputBinding', ordereddict([('prefix', 'max-post-error')])),
                                        ('type', 'float?')]),
         'save_to': ordereddict([('doc', 'Save solutions to given database'),
                                        ('inputBinding', ordereddict([('prefix', 'save-to')])),
                                        ('type', 'string?')]),
         'clip_low': ordereddict([('doc', 'Amplitude clipping - flag solutions with diagonal amplitudes below this value.'),
                                  ('inputBinding', ordereddict([('prefix', 'clip-low')])),
                                  ('type', 'float?')])}


class Recipe(object):
    """
      Functions for defining and executing a stimela recipe
    """
    def __init__(self, name, indir, outdir,
                 msdir=None,
                 cachedir=None,
                 loglevel="INFO",
                 loggername="STIMELA",
                 logfile=None,
                 toil=False):

        """
        Parameters
        ----------

        name: str
            Name of recipe.
        indir: str
            Path to directory where recipe inputs are stored
        outdir: str
            Path to directory where recipe outputs should be saved
        msdir: str|bool
            Path to directory where MS files are saved, or should be saved. If an MS will be created
        cachedir: str
            Cache directory
        loglevel: str
            Log level INFO|DEBUG|ERROR
        loggername: str
            Name of logger instance. This is useful when running multiple instances of stimela
        logfile: str
            Name of file to dump recipe logging information
        toil: bool
            Use toil runner instead of CWL reference runner
        """
        self.name = name
        self.name_ = name.lower().replace(' ', '_')
        self.indir = indir
        self.outdir = outdir
        self.cachedir = cachedir
        # Create outdir if it does not exist
        if not os.path.exists(self.outdir):
            os.mkdir(self.outdir)
        self.msdir = msdir
        self.loglevel = loglevel
        self.logfile = logfile or "log-{0:s}.txt".format(self.name_)
        self.log = logging.getLogger(loggername)
        self.log.setLevel(getattr(logging, self.loglevel))
        fh = logging.FileHandler(self.logfile, 'w')
        fh.setLevel(logging.DEBUG)
        # Create console handler with a higher log level
        ch = logging.StreamHandler(sys.stdout)
        ch.setLevel(getattr(logging, self.loglevel))
        # Create formatter and add it to the handlers
        formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
        ch.setFormatter(formatter)
        fh.setFormatter(formatter)
        # Add the handlers to logger
        self.log.addHandler(ch)
        self.log.addHandler(fh)
        self.TBC = "dummy_variable_that_no_one_will_ever_use_surely"

        self.steps = []
        self.toil = toil


    def add(self, task, label, parameters=None, doc=None, cwlfile=None, workflow=False, scatter=[]):
        """ Add task to recipe
        
        Parameters
        ----------

        task: str
            Name of task to run. For a stimela task, use the name of the cwlfile (without the .cwl extension)
            If running a task that uses a custom cwlfile, then name of the task does not have 
            to match the name of the cwlfile
        label: str
            Label for task. Must be alphanumereic
        parameters: dict
            Dictionary of input parameters and their values
        doc: str
            Task documentation. 
        cwlfile: str
            Path to cwlfile if not using a stimela cwlfile
        """
        if workflow:
            if not hasattr(task, 'workflow'):
                warnings.warn("Recipe %s is not registered. Will register"
                              " it before proceeding" % task.name)
                task.init()
            cwlfile = task.workflow.workflow_file

            # first update workflow parameters with workflow inputs
            for param in parameters:
                task.inputs[param] = parameters[param]
            parameters = task.inputs
            for param in parameters:
                if isinstance(parameters[param], dict):
                    parameters[param] = parameters[param]["path"]
        else:
            if parameters is None:
                self.log.abort("No parameters were parsed into the %s. Please review your recipe." % label)

            if task in ['cubical']:
                # Create temporary file
                tfile = tempfile.NamedTemporaryFile(suffix=".cwl", delete=False)
                tfile.flush()
                # Read the cubical cwl file
                with open(cwlfile or "{0:s}/{1:s}.cwl".format(CWLDIR, task), "r") as stdr:
                    cab = yaml.load(stdr, Loader=yaml.RoundTripLoader)
                # Assigning temporary cwl file
                cwlfile = tfile.name
                # Get the jones term to solve
                jones = parameters['sol_jones'].lower().split(',')
                # Adding the template params into the temporary cwl file with the appropriate jones terms
                for param in TMPLT:
                    for term in jones:
                        # Name of the paramaeter to be added
                        par = "%s_%s" % (term, param)
                        # Updating the prefix
                        prefix = TMPLT[param]["inputBinding"]["prefix"]
                        TMPLT[param]["inputBinding"]["prefix"] = "--{}-{}".format(term, prefix)
                        # Update the parameter list
                        cab["inputs"].insert(0, par, ordereddict(TMPLT[param]))
                        cab["inputs"][par]['inputBinding'] = ordereddict(TMPLT[param]['inputBinding'])
                with open(cwlfile, "w") as stdw:
                    yaml.dump(cab, stdw, Dumper=yaml.RoundTripDumper,
                                     default_flow_style=False)
            else:
                cwlfile = cwlfile or "{0:s}/{1:s}.cwl".format(CWLDIR, task)
            self.log.info("Adding step [{:s}] to recipe".format(task))

        step = Step(label, parameters, cwlfile, indir=self.indir, scatter=scatter)

        # add step as recipe attribute
        setattr(self, label, step)

        self.steps.append(step)

    def collect_outputs(self, outputs):
        """ Recipe outputs to save after execution. All other products will be deleted

        Parameters
        ---------

        outputs: list
            List of recipe outputs to collect (save/keep). For example, 
            if you want the collect the of step with 'step = Recipe.add(task, label)'
            you should use Recipe.collect_outputs(["label"]). If step has multiple outputs, 
            the use Recipe.collect_outputs(["label/out1", "label/out2", ...])

        """
        self.collect = outputs

    def init(self):
        """
        Initialise pipeline. This is useful if you plan on combining multiple workflows
        """
        self.workflow = Workflow(self.steps, collect=self.collect,
                                  name=self.name_, doc=self.name)

        self.workflow.create_workflow()
        self.workflow.write()
        self.inputs = self.workflow.inputs

    def run(self):
        """
        Run Recipe
        """
        if not hasattr(self, "workflow"):
            self.init()

        if self.toil:
            subprocess.check_call([
                "cwltoil",
                "--enable-ext",
                "--logFile", self.logfile,
                "--outdir", self.outdir,
                self.workflow.workflow_file,
                self.workflow.job_file,
            ])
        else:
            if self.cachedir:
                cache = ["--cachedir", self.cachedir]
            else:
                cache = []
            subprocess.check_call([
                "cwltool",
                "--enable-ext",
                "--outdir", self.outdir,
            ] + cache + [
                self.workflow.workflow_file,
                self.workflow.job_file,
            ])

        return 0
