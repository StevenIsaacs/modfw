#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# ModFW - A framework for modifying and developing devices.
# NOTE: ModFW is not a build tool. Rather it is a framework for integrating
# a variety of build and development tools.
#----------------------------------------------------------------------------
# Using a conditional here because of needing to include overrides.mk only if
# it exists.
-include overrides.mk

# Which branch of the helpers to use. Once the helpers have been cloned
# this is ignored.
HELPERS_BRANCH ?= main

# Helper scripts and utilities.
HELPERS_PATH ?= helpers
ifeq (${HELPERS_BRANCH},main)
  HELPERS_REPO := https://github.com/StevenIsaacs/modfw-helpers.git
else
  HELPERS_REPO := git@github.com:StevenIsaacs/modfw-helpers.git
endif

_helpers := ${HELPERS_PATH}/helpers.mk

# _helpers must be loaded almost immediately and defines some key variables
# such as .RECIPEPREFIX. Because of this can't rely upon make to trigger
# cloning at the correct time. Therefore, this takes a more direct approach.
_null := $(shell \
  if [ ! -f ${_helpers} ]; then \
    git clone ${HELPERS_REPO} ${HELPERS_PATH}; \
    cd ${HELPERS_PATH}; \
    git checkout ${HELPERS_BRANCH}; \
    git config pull.rebase true; \
  fi \
)

# Helper macros.
include ${_helpers}

ifneq ($(call Is-Goal,help),help)

# Config will change the sticky directory to be PROJECT specific.
$(call Use-Segment,config)

# Search path for loading segments. This can be extended by kits and mods.
$(call Add-Segment-Path,${MK_PATH})

# Common macros for ModFW segments.
$(call Use-Segment,node-macros)
$(call Use-Segment,repo-macros)

$(call Debug,STICKY_PATH = ${STICKY_PATH})

ifdef PREPEND
  $(call Use-Segment,${PREPEND})
endif

# Testing takes control of when projects, kits, and mods are loaded.
ifeq (${TESTING},)
  # Setup PROJECT specific variables and goals. A project changes the
  # STICKY_PATH to point to the project repo. This way sticky options are also # under revision control.
  $(call Use-Segment,projects)
endif # TESTING

ifdef APPEND
  $(call Use-Segment,${APPEND})
endif

#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# The entire project.
#----------------------------------------------------------------------------

# mod_deps is defined by the mod.
all: ${MAKEFILE_LIST} ${mod_deps}

# TODO: Remove this?
create-new: ${repo_goals}

# cleaners is defined by the kit and the mod.
.PHONY: clean
clean: ${cleaners}
> rm -rf ${BUILD_PATH}
> rm -rf ${STAGING_PATH}

endif # Not help.

ifneq ($(call Is-Goal,help),)
define help-Usage
Usage: make [<option>=<value> ...] [<goal>]

This is the top level make file for ModFW. NOTE: ModFW is not a build system.
Instead, ModFW is intended to integrate a variety of build systems which are
used to build both software and hardware components and projects.

This make file and the included make segments define a framework for developing
new projects or modifying existing projects. A project can consist of both
software and hardware. All of the tools and existing components needed to build
the project are automatically downloaded, configured and built when needed.

Definitions:
  deliverable: A deliverable is the end result of a ModFW run. In make
  terminology a deliverable is an end goal or target. In ModFW a deliverable is
  a file which can be:
  * A software executable or library.
  * A file describing an object which can be manufactured using a 3D printer or
    CNC.
  * A file describing a printed circuit board needed to manufacture and assemble
    the board.

  project: A ModFW project is the collection of one or more deliverables which
  serve a specific purpose.

  seg: Indicates the name of a makefile segment (included file). Changing the
  name of the file changes the name of the associated variables, macros, and
  goals.

  mod: The collection of files for a given deliverable is termed a mod.
  Semantically, a mod is a modification of an existing deliverable or a mod can
  be the development a new deliverable. A mod can be dependent upon the goals of
  other mods. Only one mod can be the "active" mod. The active mod is specified
  using the MOD variable.

  kit: A kit is a collection of mods. Each kit is a separate git repository
  and is cloned from the remote repository when needed. New kits can be created
  locally. One kit can be the "active" kit. The active kit is specified using
  the KIT variable.

  prod: Defines the mods comprising a project. This can be as simple as
  a single makefile segment but can include project documentation as well as
  goals for packaging the project deliverables. A project is maintained as a
  separate git repository. Similar to a kit, a project is automatically cloned
  when needed or can be created locally. The makefile segment for the project
  should define the kit repo URLs and branches. One project can be the "active"
  project. Sticky variables are stored in the active project directory. See
  help-helpers for more information about sticky variables. The active project
  is specified using the PROJECT variable.

  tree: ModFW uses a tree structure to organize components needed to assemble
  deliverables. This structure is similar to a classic tree structure as
  described here: https://en.wikipedia.org/wiki/Tree_(data_structure)

  node: A node for related files. A node is implemented as a directory
  in the file system. A node can be contained in another node (parent).
  Conversely, a node can contain other nodes (children).Semantically, a node serves to differentiate directories which are part of the ModFW structure apart from unrelated directories. A node must at minimum contain a makefile segment (seg) having the same name as the node itself.

  root node: A root node has no parent but has children. The ModFW directory is
  a root node. Typically the project and kit directories are children of the
  ModFW node but can exist in other locations making them root nodes as well.

  forest: A number of unconnected trees.

  repo: A node which is also a clone of a git repository.

  eng: The designer and/or developer of a project.

Repositories and branches:
  As previously mentioned projects and kits are separate git repositories. Mods
  can be dependent upon the output of other projects and kits. Different mods
  can be dependent upon different versions of projects and kits. Managing this
  potential web of dependencies can be a nightmare and lead to disk thrashing
  when switching to different branches because of mod interdependencies.
  Therefore, only one branch of a repository can be active. The branch can be
  specified at the time the repository is cloned. Thereafter, branches must be
  switched manually and all interdependent components can only use the same
  branch of a given repository.

Naming conventions:
<seg>           The name of a segment. This is used to declare segment specific
                variables and to derive directory and file names. As a result
                no two segments can have the same file name.
<seg>.mk        The name of a makefile segment. A makefile segment is designed
                to be included from another file. These should be formatted to
                contain a preamble and postamble. See help-helpers for more
                information.
GLOBAL_VARIABLE Can be overridden on the command line. Sticky variables should
                have this form unless they are for a component in which case
                the should use the <seg>.VARIABLE form (below). See
                help-helpers for more information about sticky variables.
global_variable Available to all segments but should not be overridden on the
                command line. Attempts to override can have unpredictable
                results.
<ctx>           A specific context. A context can be a segment, macro or
                group of related variables.
<ctx>.VARIABLE  A global variable prefixed with the name of specific context.
                These can be overridden on the command line.
                Component specific sticky variables should use this form.
<ctx>.variable  A global variable prefixed with the name of the context
                defining the variable. These should not be overridden.
_private_variable Make segment specific. Should not be used by other segments
                since these can be changed without concern for other segments.
callable-macro  The name of a callable macro available to all segments.
_private-macro  A private macro specific to a segment.
GlobalVariable  Camel case is used to identify variables defined by the
                helpers. This is mostly helpers.mk.
Global_Variable This form is also used by the helpers to bring more attention
                to a variable.
Callable-Macro  The name of a helper defined callable macro.

WARNING: Even though make allows variable names to begin with a numeric
character this must be avoided for all variable names since they may be
exported to the environment to be passed to a shell. If a numeric character is
used as the first character of a variable name unpredictable behavior can
occur. This is particularly important for PROJECT, KIT, MOD, and segment
names.

Overriding variables:
An overrides file, overrides.mk, is supported where the developer can preset
variables rather than having to define them on the command line. This file is
intended to be temporary and is not maintained as part of the repository (i.e.
ignored in .gitignore). The overrides.mk file is loaded immediately. None of
the helpers are available. Therefore overrides should only define variables
which would otherwise be defined on the command line.

Additional project, kit and mod specific overrides can be declared and maintained in a project repository. Unlike overrides.mk the helpers will be available to the project overrides. See help-projects for more information.

Makefile processing:
ModFW divides makefile processing into two distinct phases; pre-process and
execute.

During the pre-process phase nearly all macros are executed and makefile
segments are loaded. Any repos that are referenced are cloned or setup during
this phase. Because of this, variables should be declared using the := form. New
components (project, kit, or mod) are created during this phase. The PROJECT
component is processed first followed by the KIT component and finally the MOD
component.

The execute phase is where the typical make behavior occurs. Dependencies are
examined and resolved in this phase.

Architectural components:
Workstation     A development workstation or a system administration
                workstation.
Proxy           Manages connections between workstations and gateways. This is
                typically hosted in the cloud.
Gateway         Serves as a protocol translator between the Controller and the
                workstation.
Controller      Controls the device hardware.

Hardware platforms:
PC  = A personal computer.
SBC = A single board computer.
MCU = An embedded microcontroller.
HDW = The device or machine being controlled. For example a 3D printer.

Hardware roles:
WS  = Development or administration workstation.
UI  = User interface either command line or graphical or both.
PRX = The proxy hosted in the cloud.
GW  = Gateway (protocol translation) between the CTL and the system.
CTL = The device controller.

ModFW directly supports the following design patterns. If necessary mods
can either change the patterns or define new ones.

Design patterns:

  Direct:
  MCU_ACCESS_METHOD = direct
  Direct interface to the MCU from a PC workstation. In this case there is
  no gateway and no OS image is staged.
  +-PC----------+   +-MCU--------+   +-HDW------+
  | Workstation |<->| Controller |<->| Hardware |
  +-WS----------+ ^ +-CTL--------+ ^ +----------+
    GW            |                |
    UI            MCU defined      Hardware system bus
                  (typically a
                  serial port)

  Console:
  MCU_ACCESS_METHOD = standalone
  Similar to direct but the SBC is the user interface and a corresponding
  OS image for the SBC is staged. In this case there is no network interface.
  Software updates in this case must be performed manually at the Gateway.
  +-SBC-----+   +-MCU--------+   +-HDW------+
  | Gateway |<->| Controller |<->| Hardware |
  +-GW------+ ^ +-CTL--------+ ^ +----------+
    UI        |                |
              MCU defined      Hardware system bus
              (typically a
              serial port)

  Local network:
  MCU_ACCESS_METHOD = headless
  SSH sessions are used to communicate with the Gateway and a corresponding
  OS image for the SBC is staged. The Gateway has no keyboard or display.
  +-PC----------+   +-SBC-----+   +-MCU--------+   +-HDW------+
  | Workstation |<->| Gateway |<->| Controller |<->| Hardware |
  +-WS----------+ ^ +-GW-----=+ ^ +-CTL--------+ ^ +----------+
    UI            |   UI        |                |
                  SSH           MCU defined      Hardware system bus
                                (typically a
                                serial port)

  MCU_ACCESS_METHOD = proxied
  Secure proxied remote access using SSH tunnels. A valid ModDev package is
  required and a corresponding OS image is staged. The ModDev package is also
  used to generate scripts for accessing the gateway from the workstation and
  for accessing the proxy from either the gateway or the workstation.
  +-PC----------+   +-(cloud)+   +-SBC-----+   +-MCU--------+   +-HDW------+
  | Workstation |<->| Proxy  |<->| Gateway |<->| Controller |<->| Hardware |
  +-WS----------+ ^ +-PRX----+ ^ +-GW------+ ^ +-CTL--------+ ^ +----------+
    UI            |            |   UI        |                |
                  SSH tunnel   SSH tunnel    MCU defined      Hardware system
                                             (typically a     bus
                                             serial port)

Getting started:
All that is needed to get started is a clone of this repository and then
run make within the cloned directory. All of the necessary tools are
automatically installed within the context of the project directory so
that different projects can use different versions of tools without
conflicts between versions.

Before any actual mods can be built it is necessary to declare which project
is active,

For example:
  make PROJECT=<project> PROJECT.URL=<url> all
    Will install the project repo and activate it. Once a project is activated
    a kit can then be activated.

The active project, kit, and mod are the top level or focus. Mods can then
"use" additional mods and even mods from other kits to build components they
may be dependent upon. Dependency trees should always begin with the active
mod.

Command line options:
  Required sticky options:
  To see the variables needed by projects, kits, and mods use the corresponding
  help. e.g. make help-projects will display the help related to projects.

  For automated builds it is possible to preset options in another directory
  then overriding STICKY_PATH either in overrides.mk or on the command line.

  PREPEND = ${PREPEND}
    When defined on the command line this triggers the inclusion of a makefile
    segment named by PREPEND. This segment is loaded after loading the helpers,
    overrides, and config but before loading the project makefile segments. The
    Use-Segment macro is used to find and load the segment so segment search
    paths will be used (see help-helpers for more information).
    For example: "make PREPEND=test" will load the makefile segment named
    test.mk immediately before loading projects.mk.

  APPEND = ${APPEND}
    When defined on the command line this triggers the inclusion of a makefile
    segment named by APPEND. This segment is loaded last after all other
    segments have been loaded. The Use-Segment macro is used to find and load
    the segment so segment search paths will be used (see help-helpers for more
    information).
    For example: "make APPEND=test" will load the makefile segment named
    test.mk.

Testing the process.
  TESTING = ${TESTING}
    When this variable is not empty then the normal project processing does not
    occur. Instead, PREPEND should be used to initiate a testing process.

Command line goals:
  all             All mods for the active project are built. Use show-mod_deps
                  for a list of goals.
  create-new      Create all of the new components indicated by NEW_PROJECT,
                  NEW_KIT, and NEW_MOD (see help-projects, help-kits, or
                  help-mods).
  clean           Remove all of the build artifacts. This removes the build
                  and staging directories.

  Defined by a kit and mod:
  firmware        Build the mod firmware only.
  parts           3D printable parts only.
  os              Build the SBC OS only.
  clean           Remove the dependency files and the output files.
  reset-sticky    Resets ALL sticky variables so they have to be defined on
                  the command line again. This does not reset mod specific
                  sticky variables. For mods use the mod defined reset.
  clean-<seg>     Cleans a make segment output. See segment specific help
                  for more information.
  reset-<seg>-sticky
                  Reset segment specific variables. See segment specific
                  help for more information.

  Help and debug:
  help            Display this help message (default).
  show-mod_deps   Display the list of goals a mod is dependent upon.
  show-<variable> This is a special goal which can be used to display
                  any makefile variable and exit.
  help-<seg>      Display a make segment specific help.

endef

export _mod_fw_usage
.PHONY: help
help: help-Usage display-errors display-messages
endif # help
