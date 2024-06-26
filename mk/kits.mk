#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Manage multiple ModFW kits using git, branches, and tags.
#----------------------------------------------------------------------------
# +++++
$(call Last-Segment-UN)
ifndef ${LastSegUN}.SegID
$(call Enter-Segment,Manage multiple ModFW kits using git, branches, and tags.)
# -----

define _help
Make segment: ${Seg}.mk

A kit is a collection of mods. Each kit is expected to be maintained as a
separate git repository. The kit repository can either be local or a clone
of a remote repository. If a kit repository does not exist then one is either
cloned or created when the "mk-kit" goal is used.

The kit specific sticky variables are stored in the active project.

Within a project all kits and associated variables must have unique names.

Because different projects can use different repo branches, kit build
artifacts are stored in the kit build and staging directories.

Command line goals:
  help-<kit>
    Display the help message for a kit.
  help-${Seg}
    Display this help.
endef
help-${SegID} := $(call _help)
$(call Add-Help,${SegID})

$(call Add-Help-Section,kit-vars,Variables for managing kits.)

_var := kits
${_var} :=
define _help
${_var}
  The list of declared kits.
endef
help-${_var} := $(call _help)
$(call Add-Help,${_var})

_var := kit_node_names
${_var} := MODS_NODE BUILD_NODE STAGING_NODE
define _help
${_var}
  A kit is a repo which contains a number of mods. A kit also defines context
  for the mods withing a kit. All mods contained within a kit are contained
  within the kit directory making each of the mod directories child nodes of
  the kit node.

  Kit node names:
  <kit>.${MODS_NODE} ($${MODS_NODE})
    The name of the directory where mods are stored.
  <kit>.${BUILD_NODE} ($${BUILD_NODE})
    The name of the build artifact directory within the project build directory.
  <kit>.${STAGING_NODE} {$${STAGING_NODE}}
    The name of the staging artifact directory within the project staging
    directory.

endef
help-${_var} := $(call _help)
$(call Add-Help,${_var})

_var := kit_attributes
${_var} := URL BRANCH goals build_path staging_path
define _help
${_var}
  A kit is a ModFW repo and extends a repo with the additional attributes.

  Required attributes:
  <kit>.URL
    The URL for the kit repo.
  <kit>.BRANCH
    The branch in the kit repo to switch to when the kit is cloned.

  Additional attributes:
  <kit>.goals
    The list of goals for the kit.
  <kit>.build_path
    The path to the kit build directory. The build directory is where
    intermediate files are stored.
  <kit>.staging_path
    The path to the kit staging directory. The staging directory is where
    the kit deliverables are stored.

  The repo attributes are:
${help-repo_attributes}
endef
help-${_var} := $(call _help)
$(call Add-Help,${_var})

$(call Add-Help-Section,kit-ifs,Macros for checking kit status.)

_macro := kit-is-declared
define _help
${_macro}
  Returns a non-empty value if the kit has been declared.
endef
help-${_macro} := $(call _help)
$(call Add-Help,${_macro})
${_macro} = $(if $(filter $(1),${kits}),1)

_macro := kit-exists
define _help
${_macro}
  This returns a non-empty value if a node contains a ModFW repo.
  Parameters:
    1 = The name of a previously declared kit.
endef
help-${_macro} := $(call _help)
$(call Add-Help,${_macro})
${_macro} = $(call is-modfw-repo,$(1))

_macro := is-modfw-kit
define _help
${_macro}
  Returns a non-empty value if the kit conforms to the ModFW pattern. A
  ModFW kit will always have a makefile segment having the same name as the
  kit and the repo.
  The kit is contained in a node of the same name. The makefile segment file
  will contain the same name to indicate it is customized for the kit.
  Parameters:
    1 = The name of an existing and previously declared kit.
endef
help-${_macro} := $(call _help)
$(call Add-Help,${_macro})
define ${_macro}
$(strip
  $(call Enter-Macro,$(0),$(1))
  $(if $(call is-modfw-repo,$(1)),
    $(call Run,grep $(1) ${$(1).seg_f})
    $(if ${Run_Rc},
      $(call Verbose,grep returned:${Run_Rc})
    ,
      $(if $(wildcard ${(1).path}/.gitignore),
        1
      )
    )
  )
  $(call Exit-Macro)
)
endef

$(call Add-Help-Section,kit-decl,Macros for declaring kits.)

_macro := declare-kit
define _help
  Declare a kit as a repo and a child of the $${PROJECT}.KITS_NODE node.
  A kit can only be declared as a child of the current project.
  Parameters:
    1 = The name of the kit.
endef
help-${_macro} := $(call _help)
$(call Add-Help,${_macro})
define ${_macro}
$(call Enter-Macro,$(0),$(1))
$(if $(call kit-is-declared,$(1)),
  $(call Verbose,Kit $(1) has already been declared.)
,
  $(if $(call repo-is-declared,$(1)),
    $(call Signal-Error,\
        A repo using kit name $(1) has already been declared.)
  ,
    $(if $(call node-is-declared,$(1)),
      $(call Signal-Error,\
        A node using kit name $(1) has already been declared.)
    ,
      $(eval _ud := $(call Require,\
        PROJECT KITS_NODE BUILD_NODE STAGING_NODE $(1).URL $(1).BRANCH))
      $(if ${_ud},
        $(call Signal-Error,Undefined variables:${_ud})
      ,
        $(call Verbose,Declaring kit $(1).)
        $(if $(call node-is-declared,${KITS_NODE}),
          $(call declare-child-node,$(1),${KITS_NODE})
          $(call declare-repo,$(1))
          $(foreach _node,${kit_node_names},
            $(call declare-child-node,$(1).${${_node}},${${_node}})
          )
          $(eval kits += $(1))
        ,
          $(call Signal-Error,\
            Parent node ${KITS_NODE} for kit $(1) is not declared.)
        )
      )
    )
  )
)
$(call Exit-Macro)
endef

$(call Add-Help-Section,kit-reports,Macros for reporting kits.)

_macro := display-kit
define _help
${_macro}
  Display kit attributes.
  Parameters:
    1 = The name of the kit.
endef
help-${_macro} := $(call _help)
$(call Add-Help,${_macro})
define ${_macro}
$(call Enter-Macro,$(0),$(1))
$(if $(call kit-is-declared,$(1))
  $(call Display-Vars,\
    $(foreach _a,${kit_attributes},$(1).${_a})
  )
  $(call display-repo,$(1))
,
  $(call Warn,Kit $(1) has not been declared.)
)
$(call Exit-Macro)
endef

$(call Add-Help-Section,kit-install,Macros for cloning or creating kits.)

_macro := gen-kit-gitignore
define _help
${_macro}
  Generate the .gitignore file text for a kit.
  Parameters:
    1 = The project name.
endef
help-${_macro} := $(call _help)
$(call Add-Help,${_macro})
define ${_macro}
$(foreach _n,BUILD_NODE STAGING_NODE,
${$(1).${_n}}
)
endef

_macro := mk-kit
define _help
${_macro}
  Create and initialize a new kit repo. The kit node is declared to be
  a child of the KITS_NODE node. The node is then created and initialized
  to be a repo.

  NOTE: This is designed to be callable from the make command line using the
  helper call-${_macro} goal.
  For example:
    make ${_macro}.PARMS=<prj> call-${_macro}
  Parameters:
    1 = The node name of the new kit (<kit>).
endef
help-${_macro} := $(call _help)
$(call Add-Help,${_macro})
define ${_macro}
$(call Enter-Macro,$(0),$(1))
$(if node-is-declared,$(1),
  $(call Signal-Error,A node named $(1) has already been declared.)
,
  $(call declare-kit,$(1),${KITS_NODE})
  $(if $(call node-exists,$(1)),
    $(call Signal-Error,Kit $(1) node already exists.)
  ,
    $(call mk-node,$(1))
    $(call mk-modfw-repo,$(1))
    $(if ${Errors},
      $(call Warn,Not generating .gitignore file.)
    ,
      $(file >${$(1).path}/.gitignore,$(call gen-kit-gitignore,$(1)))
      $(call add-file-to-repo,$(1),.gitignore)
    )
  )
)
$(call Exit-Macro)
endef

_macro := mk-kit-from-template
define _help
${_macro}
  Declare and create a new kit in the KTTS_NODE node using another
  kit in the KITS_NODE node as a template.
  NOTE: This is designed to be callable from the make command line using the
  helper call-<macro> goal.
  For example:
    make ${_macro}.PARMS=<prj>:<tmpl> call-${_macro}
  Parameters:
    1 = The name of the new kit.
    2 = The name of the template kit.
endef
help-${_macro} := $(call _help)
$(call Add-Help,${_macro})
define ${_macro}
$(call Enter-Macro,$(0),$(1) $(2))
$(if node-is-declared,$(1),
  $(call Signal-Error,A node named $(1) has already been declared.)
,
  $(if $(call node-exists,$(1)),
    $(call Signal-Error,Kit $(1) node already exists.)
  ,
    $(call declare-kit,$(2),${KITS_NODE})
    $(if $(call if-kit-exists,$(2)),
      $(call declare-kit,$(1),${KITS_NODE})
      $(call mk-repo-from-template,$(1),$(2))
    ,
      $(call Signal-Error,Template kit $(2) does not exist.)
    )
  )
)
$(call Exit-Macro)
endef

_macro := install-kit
define _help
${_macro}
  Use this to install a kit repo. This clones an existing repo into
  the $${KITS_NODE} node directory.

  Parameters:
    1 = The name of the kit to install.
endef
help-${_macro} := $(call _help)
$(call Add-Help,${_macro})
define ${_macro}
$(call Enter-Macro,$(0),$(1))
$(call Info,Using kit:$(1))
$(call declare-kit,$(1))
$(if ${Errors},
,
  $(if $(call node-exists,${$(1).parent}),
    $(call install-repo,$(1))
    $(if ${Errors},
    ,
      $(if $(call is-modfw-repo,$(1)),
        $(call Verbose,Kit $(1) is a ModFW repo.)
      ,
        $(call Signal-Error,Kit $(1) is not a ModFW repo.)
      )
    )
  ,
    $(call Signal-Error,\
      Parent node ${$(1).parent} for kit $(1) does not exist.)
  )
)
$(call Exit-Macro)
endef

$(call Add-Help-Section,kit-use,The primary macro for using kits.)

_macro := use-kit
define _help
${_macro}
  Use this to install a kit repo in the kit. This clones an existing repo into
  the $${KITS_NODE} node directory.

  NOTE: This is intended to be called only from use-mod.

  Parameters:
    1 = The name of the kit to use.
endef
help-${_macro} := $(call _help)
$(call Add-Help,${_macro})
define ${_macro}
$(call Enter-Macro,$(0),$(1))
$(if ${${$(1).seg_un}.SegID},
  $(call Verbose,Kit $(1) is already in use.)
,
  $(call Info,Using kit:$(1))
  $(call install-kit,$(1))
  $(if ${Errors},
    $(call Signal-Error,An error occurred when installing the kit $(1).)
  ,
    $(call Use-Segment,${$(1).seg_f})
  )
)
$(call Exit-Macro)
endef

# +++++
# Postamble
# Define help only if needed.
__h := $(or \
  $(call Is-Goal,help-${SegUN}),\
  $(call Is-Goal,help-${SegID}),\
  $(call Is-Goal,help-${Seg}))
ifneq (${__h},)
define __help
$(call Display-Help-List,${SegID})
endef
${__h} := ${__help}
endif # help goal message.

$(call Exit-Segment)
else # SegId exists
$(call Check-Segment-Conflicts)
endif # SegId
# -----
