import glob
import re
import os.path
import sys
from collections.abc import Sequence

from omegaconf.errors import ValidationError

import stimela


from omegaconf.omegaconf import MISSING, OmegaConf
from omegaconf.dictconfig import DictConfig
from omegaconf.listconfig import ListConfig
from typing import Any, List, Dict, Optional, Union
from enum import Enum
from dataclasses import dataclass, field

## almost supported by omegaconf, see https://github.com/omry/omegaconf/issues/144, for now just use Any
# ListOrString = Union[str, List[str]]
ListOrString = Any

Conditional = Optional[str]

def EmptyDictDefault():
    return field(default_factory=lambda:{})


@dataclass
class Parameter:
    """Parameter (of cab or recipe)"""
    info: str = ""
    # for input parameters, this flag indicates a read-write (aka input-output aka mixed-mode) parameter e.g. an MS
    writeable: bool = False
    # data type
    dtype: Enum("ParamType", "bool int float str file dir ms") = MISSING
    # default value. Use MANDATORY if parameter has no default, and is mandatory
    default: Optional[str] = None
    # for file-type parameters, specifies that the filename is implicitly set inside the step (i.e. not a free parameter)
    implicit: Optional[str] = None
    # for parameters of recipes, specifies that this parameter maps onto a parameter of a constitutent step
    maps: Optional[str] = None


@dataclass
class Step:
    """Represents one processing step in a recipe"""
    cab: Optional[str] = None                       # if not None, this step is a cab and this is the cab name
    recipe: Optional["Recipe"] = None               # if not None, this step is a nested recipe
    params: Dict[str, Any] = EmptyDictDefault()     # assigns parameter values
    info: Optional[str] = None                      # comment or info

    _skip: Conditional = None                       # skip this step if conditional evaluates to true
    _break_on: Conditional = None                   # break out (of parent receipe) if conditional evaluates to true

@dataclass
class Recipe:
    """Represents a processing recipe"""
    info: str = ""
    steps: Dict[str, Step] = MISSING                # sequence of named steps

    dirs: Dict[str, Any] = EmptyDictDefault()       # I/O directory mappings

    vars: Dict[str, Any] = EmptyDictDefault()       # arbitrary collection of variables pertaining to this step (for use in substitutions)

    # Formally defines the recipe's inputs and outputs
    # See discussion in https://github.com/ratt-ru/Stimela/discussions/698#discussioncomment-362273
    # If None, these are inferred automatically from the steps' parameters
    inputs: Optional[Dict[str, Parameter]] = None
    outputs: Optional[Dict[str, Parameter]] = None

    # loop over a set of variables
    _for: Optional[Dict[str, Any]] = None
    # if not None, do a while loop with the conditional
    _while: Conditional = None
    # if not None, do an until loop with the conditional
    _until: Conditional = None


if __name__ == "__main__":
    schema = OmegaConf.structured(Recipe)

    print("=== schema for recipe ===\n")
    print(OmegaConf.to_yaml(schema, resolve=True))


    print("=== a test recipe ===\n")
    conf = OmegaConf.merge(schema, OmegaConf.create("""
    
info: 'top level receipe definition'
vars:
    ms: demo.ms
dirs:
    input: input
    output: output
steps: 
    makems:
        cab: simms
        params:
            msname: "{recipe.vars.ms}"
            telescope: kat-7
            dtime: 1
            synthesis: 0.128
    selfcal:
        params:
            ms: "{recipe.vars.ms}"      # 'recipe' refers to parent recipe
            image: final-image.fits     # overrides output filename
        recipe:
            info: "this is a generic selfcal loop"
            vars:
                scale: 30asec
                size: 256 
            _for:
                selfcal_loop: 1,2,3     # repeat three times
            steps:
                calibrate: 
                    cab: cubical
                    params:
                        ms: "{recipe.inputs.ms}"
                    _skip: "recipe.vars.selfcal_loop < 2"    # skip on first iteration, go straight to image
                image:
                    cab: wsclean
                    params:
                        msname: "{recipe.inputs.ms}"
                        name: "image-{recipe.vars.selfcal_loop}"
                        scale: "{recipe.vars.scale}"
                        size: "{recipe.vars.size}"
                evaluate:
                    cab: aimfast
                    params:
                        image: "{recipe.steps.wsclean.outputs.residual_image}"
                    _break_on: "step.outputs.dr_achieved"    # break out of recipe based on some output value
            # the below formally specifies the inputs and outputs of the selfcal recipe
            inputs:
                ms: 
                    dtype: ms
                    writeable: true
                    default: null
                # maps onto the output of the wsclean step
            outputs:
                image:
                    maps: wsclean.outputs.image
"""
    ))

    conf = OmegaConf.merge(schema, conf)

    conf.steps.mynewstep = Step(cab="xxx")
    stepname = "newstep"

    conf.steps[stepname] = Step(cab="yyy")


    print(OmegaConf.to_yaml(conf, resolve=True))
