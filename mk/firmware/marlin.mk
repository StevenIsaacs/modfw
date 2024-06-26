#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Marlin firmware
#----------------------------------------------------------------------------
# +++++
$(call Last-Segment-UN)
ifndef ${LastSegUN}.SegID
$(call Enter-Segment,Marlin firmware)
# -----

#+
# Config section.
#
# For custom Marlin mods.
#
# The Marlin configurations are installed to serve as starting points
# for new mods or for comparison with existing mods.
#-
ifndef ${mlnSegN}_VERSION
  ${mlnSegN}_VERSION := bugfix-2.0.x
endif
ifeq (${${mlnSegN}_VERSION},dev)
  ${mlnSegN}_REPO := git@github.com:StevenIsaacs/Marlin.git
  ${mlnSegN}_PATH := ${TOOLS_PATH}/marlin-dev
  ${mlnSegN}_CONFIG_REPO := git@github.com:StevenIsaacs/Configurations.git
  ${mlnSegN}_CONFIG_PATH := ${TOOLS_PATH}/marlin-configs-dev
else
  ${mlnSegN}_REPO := https://github.com/MarlinFirmware/Marlin.git
  ${mlnSegN}_PATH := ${TOOLS_PATH}/marlin
  ${mlnSegN}_CONFIG_REPO := https://github.com/MarlinFirmware/Configurations.git
  ${mlnSegN}_CONFIG_PATH := ${TOOLS_PATH}/marlin-configs
endif

#+
# For Platformio which is used to build the Marlin firmware.
#-
_${mlnSegN}_pio_requirements := ${pio_venv_requirements}

_${mlnSegN}_build_path := ${${mlnSegN}_PATH}/.pio/build

$(call Use-Segment,firmware/platformio)

#+
# For Marlin.
#-
_${mlnSegN}_install_file := ${${mlnSegN}_PATH}/README.md

_${mlnSegN}_config_install_file := ${${mlnSegN}_CONFIG_PATH}/README.md

${_${mlnSegN}_install_file}:
> git clone ${${mlnSegN}_REPO} ${${mlnSegN}_PATH}; \
> cd ${${mlnSegN}_PATH}; \
> git checkout ${${mlnSegN}_VERSION}

$(_${mlnSegN}_config_install_file):
> git clone ${${mlnSegN}_CONFIG_REPO} ${${mlnSegN}_CONFIG_PATH}; \
> cd ${${mlnSegN}_CONFIG_PATH}; \
> git checkout ${${mlnSegN}_VERSION}

_${mlnSegN}_deps := \
  ${_${mlnSegN}_pio_requirements} \
  ${_${mlnSegN}_install_file} \
  $(_${mlnSegN}_config_install_file)

${mlnSeg}: ${_${mlnSegN}_deps}

#+
# All the files maintained for this mod.
#-
_${mlnSegN}_mod_files := $(shell find ${MOD_FIRMWARE_PATH}/marlin -type f)

_${mlnSegN}_firmware := ${_${mlnSegN}_build_path}/${${mlnSegN}_MOD_BOARD}/${${mlnSegN}_FIRMWARE}

#+
# To build Marlin using the mod files.
# NOTE: The mod directory structure is expected to match the Marlin
# directory structure.
#-
${_${mlnSegN}_firmware}: ${_${mlnSegN}_deps} ${_${mlnSegN}_mod_files}
> cd ${${mlnSegN}_PATH}; git checkout .; git checkout ${${mlnSegN}_VERSION}
> cp -r ${MOD_PATH}/Marlin/* ${${mlnSegN}_PATH}/Marlin
> . ${pio_venv_path}/bin/activate; \
> cd ${${mlnSegN}_PATH}; \
> platformio run -e ${${mlnSegN}_MOD_BOARD}; \
> deactivate

mod_firmware := ${MOD_STAGING_PATH}/${${mlnSegN}_FIRMWARE}

${mod_firmware}: ${_${mlnSegN}_firmware}
> mkdir -p $(@D)
> cp $< $@

${mlnSeg}-firmware: ${mod_firmware}

# +++++
# Postamble
__h := $(or $(call Is-Goal,help-${SegUN}),$(call Is-Goal,help-${SegID}))
ifneq (${__h},)
$(call Attention,Generating help for:${Seg})
define __help
Make segment: ${Seg}.mk

Marlin firmware is typically used to control 3D printers but can also be
used for CNC and Laser cutters/engravers.

This segment is used to build the Marlin firmware using the mod specific
source files. The mod specific source files are copied to the Marlin
source tree before building the firmware. The mod specific source tree is
expected to match the Marlin source tree so a simple recursive copy can
be used to modify the Marlin source. A git checkout is used to return the
Marlin source tree to its original cloned state.

Defined in mod.mk:
  ${mlnSegN}_VERSION := ${${mlnSegN}_VERSION}
    The release or branch of the Marlin source code to use for the mod.
    If undefined then a default will be used. If using the dev variant
    then valid github credentials are required.
  ${mlnSegN}_MOD_BOARD := ${${mlnSegN}_MOD_BOARD}
    The CAM controller board.
  ${mlnSegN}_FIRMWARE := ${${mlnSegN}_FIRMWARE}
    The name of the file produced by the Marlin build to be installed on
    the CAM controller board.

Defined in kits.mk:
  MOD_STAGING_PATH := ${MOD_STAGING_PATH}
    Where the firmware image is staged.

Defines:
  ${mlnSegN}_REPO := ${${mlnSegN}_REPO}
    The URL of the repo to clone the Marlin source from.
  ${mlnSegN}_VERSION := ${${mlnSegN}_VERSION}
    The branch to use for building the Marlin firmware.
  ${mlnSegN}_PATH := ${${mlnSegN}_PATH}
    Where to clone the Marlin source to.
  ${mlnSegN}_CONFIG_REPO := ${${mlnSegN}_CONFIG_REPO}
    The existing Marlin configurations which can be used as starting point
    for a new mod.
  ${mlnSegN}_CONFIG_PATH := ${${mlnSegN}_CONFIG_PATH}
    Where to clone the Marlin configurations to.
  mod_firmware := ${mod_firmware}
    The dependencies to build the firmware.

Uses:
  platformio.mk The PlatformIO tool for building firmware.

Command line goals:
  ${mlnSeg}
    Install the Marlin source code and PlatformIO.
  ${mlnSeg}-firmware
    Build the Marlin firmware using the mod source files.
    Display this help.
endef
${__h} := ${__help}
endif
$(call Exit-Segment)
else
$(call Check-Segment-Conflicts)
endif # SegId
# -----
