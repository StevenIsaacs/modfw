#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Manage multiple ModFW kits using git, branches, and tags.
#----------------------------------------------------------------------------
# +++++
$(call Last-Segment-UN)
ifndef ${LastSegUN}.SegID
$(call Enter-Segment)
# -----

# A kit is a collection of mods. Each kit is a separate git repo.
# The directory containing the kit repos.
$(call Overridable,DEFAULT_KITS_DIR,$(Seg))
# Where the mod kits are cloned to.
# NOTE: This is ignored in .gitignore.
$(call Overridable,DEFAULT_KITS_PATH,${${PROJECT}.path}/${DEFAULT_KITS_DIR})

$(call Sticky,KITS_DIR,${DEFAULT_KITS_DIR})
$(call Sticky,KITS_PATH,${DEFAULT_KITS_PATH})

$(call declare-node,${KITS_DIR},,${KITS_PATH})
$(call create-node,${KITS_DIR})

${Seg} :=

_macro := new-kit
define _help
${_macro}
  Create and initialize a new kit repo. A makefile segment is generated from
  a template. The dev must then complete the makefile segment before attempting
  a build.
  NOTE: This is designed to be callable from the make command line using the
  helpers call-<macro> goal.
  For example:
    make ${_macro}.PARMS=<kit>[:<basis>] call-${_macro}
  Parameters:
    1 = The name of the new kit.
    2 = Optional kit name to use as the basis of the new kit.
endef
help-${_macro} := $(call _help)
define ${_macro}
$(call Enter-Macro,$(0),$(1))
$(if $(call repo-is-setup,$(1)),
  $(call Signal-Error,Kit $(1) already exists -- not creating.)
,
  $(call new-repo,$(1),${KITS_DIR},$(2))
)
$(call Exit-Macro)
endef

_macro := use-kit
define _help
${_macro}
  Use this to install a kit repo in the project. This clones an existing repo
  into the parent node directory.
  Parameters:
    1 = The name of the kit to use.
endef
help-${_macro} := $(call _help)
define ${_macro}
$(call Enter-Macro,$(0),$(1))
$(if ${$(1).SegID},
  $(call Debug,Kit $(1) is already in use.)
,
  $(call declare-repo,$(1),${KITS_DIR})
  $(call use-repo,$(1))
  $(if $(call is-modfw-repo,$(1)),
    $(call Info,Using kit:$(1))
    $(call Use-Segment,$(1))
    $(eval ${Seg} += $(1))
  ,
    $(call Signal-Error,$(1) is not a ModFW repo.)
  )
)
$(call Exit-Macro)
endef

# To remove all kits.
ifneq ($(call Is-Goal,remove-${KITS_DIR}),)

  $(call Info,Removing all kits in: ${KITS_PATH})
  $(call Warn,This cannot be undone!)
  ifeq ($(call Confirm,Remove all ${KITS_DIR} -- can not be undone?,y),y)

remove-${KITS_DIR}:
> rm -rf ${KITS_PATH}

  else
    $(call Info,Not removing ${KITS_DIR}.)
  endif
endif

# +++++
# Postamble
# Define help only if needed.
ifneq ($(call Is-Goal,help-${Seg}),)
define help_${SegV}_msg
Make segment: ${Seg}.mk

A kit is a collection of mods. Each kit is assumed to be maintained as a
separate git repository. The kit repository can either be local or a clone
of a remote repository. If a kit repository does not exist then one is either
cloned or created when the "create-kit" goal is used.

Only one kit is the active kit and is identified by the KIT sticky variable.
Mods can use additional kits using the "use-repo" macro (see help-repo-macros).

A set of kit specific variables (attributes) are defined for each kit being
used.

The kit specific sticky variables are stored in the active project.

Defined in config.mk:
  KITS_PATH = ${KITS_PATH}
    Where mod kits are installed (cloned from a git repo).
  STAGING_PATH = ${STAGING_PATH}
    The top level staging directory.

See help-repo_attributes for additional sticky variables.

${help-new-kit}

${help-use-kit}

Command line goals:
  call-new-kit
    Create a new kit. See help-new-kit for more info.
  show-${Seg}
    Display a list of kits which are in use.
  help-<kit>
    Display the help message for a kit.
  help-${Seg}
    Display this help.
endef
endif # help goal message.

$(call Exit-Segment)
else # SegId exists
$(call Check-Segment-Conflicts)
endif # SegId
# -----
