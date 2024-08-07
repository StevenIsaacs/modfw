#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Manage multiple ModFW kits using git, branches, and tags.
#----------------------------------------------------------------------------
# +++++
$(call Last-Segment-UN)
ifndef ${LastSegUN}.SegID
$(call Enter-Segment,Manage multiple ModFW kits using git, branches, and tags.)
# -----

$(call Use-Segment,repos)

define _help
Make segment: ${Seg}.mk

A kit is a collection of mods. Each kit is expected to be maintained as a
separate git repository. The kit repository can either be local or a clone
of a remote repository.

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

_var := kit_ignored_nodes
${_var} := BUILD_NODE STAGING_NODE
define _help
${_var}
  These nodes are not part of the git repository and therefore are ignored using
  .gitignore.
endef
help-${_var} := $(call _help)
$(call Add-Help,${_var})

_var := kit_node_names
${_var} := MODS_NODE $(kit_ignored_nodes)
define _help
${_var}
  A kit is a repo which contains a number of mods. A kit also defines context
  for the mods withing a kit. All mods contained within a kit are contained
  within the kit directory making each of the mod directories child nodes of
  the kit node.

Kit node names:
$(foreach _node,${kit_node_names},
$(call help-${_node})
)
endef
help-${_var} := $(call _help)
$(call Add-Help,${_var})

_var := kit_attributes
${_var} := goals mods_path build_path staging_path
define _help
${_var}
  A kit is a ModFW repo and extends a repo with the additional attributes.

  Attributes:
  <kit>.goals
    The list of goals for the kit.
  <kit>.mods
    The list of declared mods in the kit.
  <kit>.mods_path
    Where mods are stored within the kit.
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
  This returns a non-empty value if a kit node contains a ModFW repo.
  Parameters:
    1 = The name of a previously declared kit.
endef
help-${_macro} := $(call _help)
$(call Add-Help,${_macro})
${_macro} = $(call is-modfw-repo,$(1))

_macro := kit-has-declared-mods
define _help
${_macro}
  This returns a non-empty value if the kit has declared mods.
  Parameters:
    1 = The name of a previously declared kit.
endef
help-${_macro} := $(call _help)
$(call Add-Help,${_macro})
${_macro} = $(if ${$(1).mods},1)

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
  $(call Enter-Macro,$(0),kit=$(1))
  $(if $(call is-modfw-repo,$(1)),
    $(call Run,grep $(1) ${$(1).seg_f})
    $(if ${Run_Rc},
      $(call Verbose,grep returned:${Run_Rc})
    ,
      $(if $(wildcard ${$(1).path}/.gitignore),
        $(call Verbose,$(1) is a valid ModFW kit.)
        1
      ,
        $(call Verbose,${(1).path}/.gitignore does not exist.)
      )
    )
  ,
    $(call Verbose,$(1) is not a ModFW repo.)
  )
  $(call Exit-Macro)
)
endef

$(call Add-Help-Section,kit-decl,Macros for declaring kits.)

_macro := declare-kit
define _help
  Declare a kit as a repo and a child of the $${PROJECT}.$${KITS_NODE} node.
  A kit can only be declared as a child of the current project.
  Parameters:
    1 = The name of the kit.
endef
help-${_macro} := $(call _help)
$(call Add-Help,${_macro})
define ${_macro}
$(call Enter-Macro,$(0),kit=$(1) parent=${PROJECT}.${KITS_NODE})
$(if $(call kit-is-declared,$(1)),
  $(call Attention,Kit $(1) has already been declared.)
,
  $(if $(call repo-is-declared,$(1)),
    $(call Signal-Error,\
        A repo using kit name $(1) has already been declared.)
  ,
    $(if $(call node-is-declared,$(1)),
      $(call Signal-Error,\
        A node using kit name $(1) has already been declared.)
    ,
      $(if ${$(1).URL},
      ,
        $(eval $(1).URL := ${DEFAULT_KIT_URL}/$(1))
      )
      $(call Attention,Using url:${$(1).URL})
      $(if ${$(1).BRANCH},
      ,
        $(eval $(1).BRANCH := ${DEFAULT_BRANCH})
      )
      $(call Attention,Using branch:${$(1).BRANCH})
      $(eval _ud := $(call Require,PROJECT KITS_NODE ${kit_node_names}))
      $(if ${_ud},
        $(call Signal-Error,Undefined variables:${_ud})
      ,
        $(if $(call node-is-declared,${PROJECT}.${KITS_NODE}),
          $(call Verbose,Declaring kit $(1).)
          $(call declare-child-node,$(1),${PROJECT}.${KITS_NODE})
          $(call declare-repo,$(1))
          $(foreach _node,${kit_node_names},
            $(call declare-child-node,$(1).${${_node}},$(1),${${_node}})
          )
          $(eval $(1).goals :=)
          $(eval $(1).mods_path := ${$(1).${MODS_NODE}.path})
          $(eval $(1).build_path := ${$(1).${BUILD_NODE}.path})
          $(eval $(1).staging_path := ${$(1).${STAGING_NODE}.path})
          $(eval kits += $(1))
        ,
          $(call Signal-Error,\
            Parent node ${PROJECT}.${KITS_NODE} for kit $(1) is not declared.)
        )
      )
    )
  )
)
$(call Exit-Macro)
endef

_macro := undeclare-kit
define _help
  Remove a kit declaration. The corresponding repo and node are also
  undeclared. The non-sticky kit attributes are undefined.
  Parameters:
    1 = The name of the kit.
endef
help-${_macro} := $(call _help)
$(call Add-Help,${_macro})
define ${_macro}
$(call Enter-Macro,$(0),kit=$(1))

$(if $(call kit-is-declared,$(1)),
  $(if $(call repo-is-declared,$(1)),
    $(if $(call node-is-declared,$(1)),
      $(if $(call is-a-child-node,$(1)),
        $(call undeclare-repo,$(1))
        $(foreach _node,${$(1).children},
          $(call undeclare-child-node,${_node})
        )
        $(call undeclare-child-node,$(1))
        $(foreach _att,${kit_attributes},
          $(eval undefine $(1).${_att})
        )
        $(eval kits := $(filter-out $(1),${kits}))
      ,
        $(call Signal-Error,Kit $(1) is not a child node.)
      )
    ,
      $(call Signal-Error,Kit $(1) does not have a declared node.)
    )
  ,
    $(call Signal-Error,Kit $(1) does not have a declared repo.)
  )
,
  $(call Signal-Error,The kit $(1) has not been declared.)
)
$(call Exit-Macro)
endef

_macro := register-mod
define _help
${_macro}
  Add a mod to a kit declared mod list.
  Parameters:
    1 = The kit.mod reference for the mod (name of the mod's node).
    2 = The kit containing the mod.
endef
help-${_macro} := $(call _help)
$(call Add-Help,${_macro})
define ${_macro}
$(call Enter-Macro,$(0),mod=$(1) kit=$(2))
$(if $(call kit-is-declared,$(2)),
  $(eval $(2).mods += ${$(1).mod})
  $(call Verbose,Kit $(2) mods are:${$(2).mods})
,
  $(call Signal-Error,Kit $(2) has not been declared.)
)
$(call Exit-Macro)
endef

_macro := unregister-mod
define _help
${_macro}
  Remove a mod from a kit declared mod list.
  Parameters:
    1 = The kit.mod reference for the mod (name of the mod's node).
    2 = The kit containing the mod.
endef
help-${_macro} := $(call _help)
$(call Add-Help,${_macro})
define ${_macro}
$(call Enter-Macro,$(0),mod=$(1) kit=$(2))
$(if $(call kit-is-declared,$(2)),
  $(call Verbose,Kit $(2) is declared.)
  $(eval $(2).mods := $(filter-out ${$(1).mod},${$(2).mods}))
  $(call Verbose,Kit $(2) mods are:${$(2).mods})
,
  $(call Signal-Error,Kit $(2) has not been declared.)
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
$(call Enter-Macro,$(0),kit=$(1))
$(if $(call kit-is-declared,$(1)),
  $(call Display-Vars,\
    $(foreach _a,${kit_attributes},$(1).${_a}) \
    $(foreach _a,${kit_node_names},$(1).${_a})
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
  Generate the .gitignore file text for a kit. The ignored items are relative
  to the kit directory.
  Parameters:
    1 = The kit name.
endef
help-${_macro} := $(call _help)
$(call Add-Help,${_macro})
define ${_macro}
$(eval _out := ${$(1).path}/.gitignore)
$(file >${_out},# Generated by $(0) for kit $(1).)
$(foreach _n,${kit_ignored_nodes},
  $(file >>${_out},${$(1).${${_n}}.dir})
)
endef

_macro := mk-kit
define _help
${_macro}
  Create and initialize a new kit repo. The kit node is declared to be
  a child of the $${PROJECT}.$${KITS_NODE} node. The node is then created and
  initialized to be a repo.

  If the node for the kit has already been declared then the existing
  declaration is used.

  Use rm-kit to remove a kit.

  NOTE: This is designed to be callable from the make command line using the
  helper call-${_macro} goal.
  For example:
    make ${_macro}.PARMS=<kit> [<kit>.URL=<url>] [<kit>.BRANCH=<branch>] call-${_macro}
  Parameters:
    1 = The node name of the new kit (<kit>).
endef
help-${_macro} := $(call _help)
$(call Add-Help,${_macro})
$(call Declare-Callable-Macro,${_macro})
define ${_macro}
$(call Enter-Macro,$(0),kit=$(1))
$(call Clear-Errors)
$(if ${$(1).URL},
  $(call Attention,Using url:${$(1).URL})
,
  $(eval $(1).URL := ${DEFAULT_KIT_URL}/$(1))
)
$(if ${$(1).BRANCH},
  $(call Attention,Using branch:${$(1).BRANCH})
,
  $(eval $(1).BRANCH := ${DEFAULT_BRANCH})
)
$(call declare-kit,$(1))
$(if ${Errors},
  $(call Attention,Unable to make a kit.)
,
  $(if $(call node-exists,$(1)),
    $(call Signal-Error,Kit $(1) node already exists.)
  ,
    $(call mk-node,$(1))
    $(call mk-modfw-repo,$(1))
    $(if ${Errors},
      $(call Warn,An error occurred -- not generating .gitignore file.)
    ,
      $(call gen-kit-gitignore,$(1))
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

  If the kit has already been declared then the existing kit declaration is
  used.

  For example:
    make ${_macro}.PARMS=<prj>:<tmpl> call-${_macro}
  Parameters:
    1 = The name of the new kit.
    2 = The name of the template kit.
endef
help-${_macro} := $(call _help)
$(call Add-Help,${_macro})
$(call Declare-Callable-Macro,${_macro})
define ${_macro}
$(call Enter-Macro,$(0),kit=$(1) template=$(2))

$(call declare-kit,$(1))
$(if ${Errors},
  $(call Attention,Unable to make a kit.)
,
  $(if $(call node-exists,$(1)),
    $(call Signal-Error,Kit $(1) node already exists.)
    $(call undeclare-kit,$(1))
  ,
    $(call declare-kit,$(2))
    $(if $(call is-modfw-repo,$(2)),
      $(call mk-repo-from-template,$(1),$(2))
    ,
      $(call Signal-Error,Template kit $(2) does not exist.)
      $(call undeclare-kit,$(1))
      $(call undeclare-kit,$(2))
    )
  )
)
$(call Exit-Macro)
endef

_macro := rm-kit
define _help
${_macro}
  Remove an existing kit. The kit node is declared to be a child of
  the KITS_NODE node within the ${PROJECT} project. The node is then removed.

  NOTE: This is designed to be callable from the make command line using the
  helper call-${_macro} goal.
  For example:
    make ${_macro}.PARMS=<kit> call-${_macro}

  Parameters:
    1 = The node name of the kit to remove(<prj>).
endef
help-${_macro} := $(call _help)
$(call Add-Help,${_macro})
$(call Declare-Callable-Macro,${_macro})
define ${_macro}
  $(call Enter-Macro,$(0),kit=$(1))
  $(call Clear-Errors)
  $(call declare-child-node,$(1),${KITS_NODE})
  $(if ${Errors},
    $(call Attention,Unable to remove kit $(1).)
  ,
    $(if $(call node-exists,$(1)),
      $(call rm-node,$(1),Remove kit $(1) from project ${PROJECT}?)
      $(if ${Errors},
        $(call Warn,An error occurred when removing kit $(1).)
      )
    ,
      $(call Signal-Error,Kit $(1) node does not exist.)
    )
     $(call undeclare-node,$(1))
  )
  $(call Exit-Macro)
endef

_macro := install-kit
define _help
${_macro}
  Use this to install a kit repo. This declares and clones an existing repo into
  the $${KITS_NODE} node directory.

  If the kit has already been declared then the existing kit declaration is
  used.

  Parameters:
    1 = The name of the kit to install.
endef
help-${_macro} := $(call _help)
$(call Add-Help,${_macro})
define ${_macro}
$(call Enter-Macro,$(0),kit=$(1))

$(call declare-kit,$(1))
$(if ${Errors},
  $(call Attention,Unable to install a kit.)
,
  $(if $(call node-exists,${$(1).parent}),
    $(call install-repo,$(1))
    $(if ${Errors},
    ,
      $(if $(call is-modfw-repo,$(1)),
        $(call Verbose,Kit $(1) is a ModFW repo.)
      ,
        $(call Signal-Error,Kit $(1) is not a ModFW repo.)
        $(if ${VERBOSE},$(call display-kit,$(1)))
      )
    )
  ,
    $(call Signal-Error,Parent node ${$(1).parent} for kit $(1) does not exist.)
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
$(call Enter-Macro,$(0),kit=$(1))
$(if ${${$(1).seg_un}.SegID},
  $(call Verbose,Kit $(1) is already in use.)
,
  $(call Info,Using kit:$(1))
  $(call install-kit,$(1))
  $(if ${Errors},
    $(call Signal-Error,An error occurred when installing the kit $(1).)
  ,
    $(foreach _node,${kit_node_names},
      $(if $(call node-exists,$(1).${${_node}}),
        $(call Info,Using existing node $(1).${${_node}})
      ,
        $(call mk-node,$(1).${${_node}})
      )
    )
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
