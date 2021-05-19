from collections import OrderedDict
import dataclasses
from stimela import configuratt
from scabha.exceptions import ScabhaBaseException
from omegaconf.omegaconf import OmegaConf, OmegaConfBaseException
import click
import logging
import os.path, yaml
from typing import List, Optional
import stimela
from stimela import logger
from stimela.main import cli
from stimela.kitchen.recipe import Recipe, Step, join_quote
from stimela.config import get_config_class


@cli.command("exec",
    help="""
    Execute a single cab, or a recipe from a YML file. 
    If the YML files contains multiple recipes, specify the recipe name as an extra argument.
    Use PARAM=VALUE to specify parameters for the recipe or cab. You can also use X.Y.Z=FOO to
    change any and all config and/or recipe settings.
    """,
    no_args_is_help=True)
@click.option("-s", "--step", "step_names", metavar="STEP", multiple=True,
                help="""only runs specific step(s) from the recipe. Can be given multiple times to cherry-pick steps.
                Use [BEGIN]:[END] to specify a range of steps.""")
@click.argument("what", metavar="filename.yml|CAB") 
@click.argument("parameters", nargs=-1, metavar="[recipe name] [PARAM=VALUE] [X.Y.Z=FOO] ...", required=False) 
def exxec(what: str, parameters: List[str] = [],  
        step_names: List[str] = []):

    log = logger()
    params = OrderedDict()
    dotlist = []
    errcode = 0
    recipe_name = None

    # parse arguments as recipe name, parameter assignments, or dotlist for OmegaConf    
    for pp in parameters:
        if "=" not in pp:
            if recipe_name is not None:
                log.error(f"multiple recipe names given")
                errcode = 2
            recipe_name = pp
        else:
            key, value = pp.split("=", 1)
            # dotlist
            if '.' in key:
                dotlist.append(pp)
            # else param=value
            else:
                # parse string as yaml value
                try:
                    params[key] = yaml.safe_load(value)
                except Exception as exc:
                    log.error(f"error parsing '{pp}': {exc}")
                    errcode = 2

    if errcode:
        return errcode

    # load extra config settigs from dotkey arguments, to be merged in below
    # (when loading a recipe file, we want to merge these in AFTER the recipe is loaded, because the arguments
    # might apply to the recipe)
    try:
        extra_config = OmegaConf.from_dotlist(dotlist) if dotlist else OmegaConf.create()
    except OmegaConfBaseException as exc:
        log.error(f"error loading command-line dotlist: {exc}")
        return 2

    if what in stimela.CONFIG.cabs:
        cabname = what

        try:
            stimela.CONFIG = OmegaConf.merge(stimela.CONFIG, extra_config)
        except OmegaConfBaseException as exc:
            log.error(f"error applying command-line dotlist: {exc}")
            return 2

        log.info(f"setting up cab {cabname}")

        # create step config by merging in settings (var=value pairs from the command line) 
        step = Step(cab=cabname, params=params)

    else:
        if not os.path.isfile(what):
            log.error(f"'{what}' is neither a recipe file nor a known stimela cab")
            return 2 

        log.info(f"loading recipe/config {what}")

        # if file contains a recipe entry, treat it as a full config (that can include cabs etc.)
        try:
            conf = configuratt.load_using(what, stimela.CONFIG)
        except OmegaConfBaseException as exc:
            log.error(f"Error loading {what}: {exc}")
            return 2

        # anything that is not a standard config section will be treated as a recipe
        all_recipe_names = [name for name in conf if name not in stimela.CONFIG]
        if not all_recipe_names:
            log.error(f"{what} does not contain any recipies")
            return 2

        log.info(f"{what} contains the following recipe sections: {join_quote(all_recipe_names)}")

        if recipe_name:
            if recipe_name not in conf:
                log.error(f"{what} does not contain a '{recipe_name}' section")
                return 2
        else:
            if len(all_recipe_names) > 1: 
                log.error(f"multiple receipes found, please specify a particular one")
                return 2
            recipe_name = all_recipe_names[0]
        
        # merge into config, treating each section as a recipe
        config_fields = []
        for section in conf:
            if section not in stimela.CONFIG:
                config_fields.append((section, Optional[Recipe], dataclasses.field(default=None)))
        dcls = dataclasses.make_dataclass("UpdatedStimelaConfig", config_fields, bases=(get_config_class(),)) 
        config_schema = OmegaConf.structured(dcls)

        try:
            stimela.CONFIG = OmegaConf.merge(stimela.CONFIG, config_schema, conf, extra_config)
        except OmegaConfBaseException as exc:
            log.error(f"Error loading {what}: {exc}")
            return 2

        log.info(f"selected recipe is '{recipe_name}'")

        # create recipe object from the config
        try:
            recipe = Recipe(**stimela.CONFIG[recipe_name])
        except ScabhaBaseException as exc:
            if not exc.logged:
                log.error(f"Error loading recipe '{recipe_name}': {exc}")
            return 2

        # select substeps if so specified
        if step_names:
            restrict = []
            all_step_names = list(recipe.steps.keys())
            for name in step_names:
                if ':' in name:
                    begin, end = name.split(':', 1)
                    if begin:
                        try:
                            first = all_step_names.index(begin)
                        except ValueError as exc:
                            log.error(f"No such recipe step: '{begin}")
                            return 2
                    else:
                        first = 0
                    if end:
                        try:
                            last = all_step_names.index(end)
                        except ValueError as exc:
                            log.error(f"No such recipe step: '{begin}")
                            return 2
                    else:
                        last = len(recipe.steps)-1
                    restrict += all_step_names[first:last+1]
                else:
                    recipe.enable_step(name)  # a single step is force-enabled if skipped in config file
                    restrict.append(name)
            recipe.restrict_steps(restrict, force_enable=False)

            if any(step.skip for step in recipe.steps.values()):
                steps =[f"({label})" if step.skip else label for label, step in recipe.steps.items()]
                log.warning(f"running partial recipe (skipped steps given in parentheses):")
                log.warning(f"    {' '.join(steps)}")

            # warn user if som steps remain explicitly disabled
            if any(recipe.steps[label].skip for label in restrict):
                log.warning("note that some steps remain explicitly skipped, you can enable them with -s")

        # wrap it in an outer step
        step = Step(recipe=recipe, info=what, params=params)

    # prevalidate() is done by run() automatically if not already done, so we only need this in debug mode, so that we
    # can pretty-print the recipe
    if log.isEnabledFor(logging.DEBUG):
        try:
            step.prevalidate()
        except ScabhaBaseException as exc:
            if not exc.logged:
                log.error(f"pre-validation failed: {exc}")
            return 1

        log.debug("---------- prevalidated step follows ----------")
        for line in step.summary():
            log.debug(line)

    # run step

    try:
        outputs = step.run()
    except ScabhaBaseException as exc:
        if not exc.logged:
            log.error(f"run failed with exception: {exc}")
        return 1

    if outputs:
        log.info("run successful, outputs follow:")
        for name, value in outputs.items():
            log.info(f"  {name}: {value}")
    else:
        log.info("run successful")


    return 0
