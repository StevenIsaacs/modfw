#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Marlin firmware
#----------------------------------------------------------------------------

include ${FIRMWARE_MK_PATH}/platformio.mk

#+
# Config section.
#
# For custom Marlin mods.
#
# The Marlin configurations are installed to serve as starting points
# for new mods or for comparison with existing mods.
#-
ifndef marlin_VARIANT
  marlin_VARIANT = bugfix-2.0.x
endif
ifeq (${marlin_VARIANT},dev)
  marlin_REPO = git@github.com:StevenIsaacs/Marlin.git
  marlin_VARIANT = dev
  marlin_PATH = ${TOOLS_PATH}/marlin-dev
  marlin_CONFIG_REPO = git@github.com:StevenIsaacs/Configurations.git
  marlin_CONFIG_PATH = ${TOOLS_PATH}/marlin-configs-dev
else
  marlin_REPO = https://github.com/MarlinFirmware/Marlin.git
  marlin_VARIANT = ${marlin_VARIANT}
  marlin_PATH = ${TOOLS_PATH}/marlin
  marlin_CONFIG_REPO = https://github.com/MarlinFirmware/Configurations.git
  marlin_CONFIG_PATH = ${TOOLS_PATH}/marlin-configs
endif

#+
# For Platformio which is used to build the Marlin firmware.
#-
_PlatformIoRequirements = ${PioVenvRequirements}

_MarlinBuildPath = ${marlin_PATH}/.pio/build

_MarlinInstallFile = ${marlin_PATH}/README.md

_MarlinConfigInstallFile = ${marlin_CONFIG_PATH}/README.md

${_MarlinInstallFile}:
> git clone ${marlin_REPO} ${marlin_PATH}; \
> cd ${marlin_PATH}; \
> git checkout ${marlin_VARIANT}

$(_MarlinConfigInstallFile):
> git clone ${marlin_CONFIG_REPO} ${marlin_CONFIG_PATH}; \
> cd ${marlin_CONFIG_PATH}; \
> git checkout ${marlin_VARIANT}

_MarlinDeps = \
  ${_PlatformIoRequirements} \
  ${_MarlinInstallFile} \
  $(_MarlinConfigInstallFile)

marlin: ${_MarlinDeps}

#+
# All the files maintained for this mod.
#-
_MarlinModFiles = $(shell find ${MOD_PATH}/Marlin -type f)

_MarlinFirmware = ${_MarlinBuildPath}/${marlin_MOD_BOARD}/${marlin_FIRMWARE}

#+
# To build Marlin using the mod files.
# NOTE: The mod directory structure is expected to match the Marlin
# directory structure.
#-
${_MarlinFirmware}: ${_MarlinDeps} ${_MarlinModFiles}
> cd ${marlin_PATH}; git checkout .; git checkout ${marlin_VARIANT}
> cp -r ${MOD_PATH}/Marlin/* ${marlin_PATH}/Marlin
> . ${PioVirtualEnvPath}/bin/activate; \
> cd ${marlin_PATH}; \
> platformio run -e ${marlin_MOD_BOARD}; \
> deactivate

ModFirmware = ${MOD_STAGING_PATH}/${marlin_FIRMWARE}

${ModFirmware}: ${_MarlinFirmware}
> mkdir -p $(@D)
> cp $< $@

firmware: ${ModFirmware}


ifeq (${MAKECMDGOALS},help-marlin)
define HelpMarlinMsg
Make segment: marlin.mk

Marlin firmware is typically used to control 3D printers but can also be
used for CNC and Laser cutters/engravers.

This segment is used to build the Marlin firmware using the mod specific
source files. The mod specific source files are copied to the Marlin
source tree before building the firmware. The mod specific source tree is
expected to match the Marlin source tree so a simple recursive copy can
be used to modify the Marlin source. A git checkout is used to return the
Marlin source tree to its original cloned state.

Defined in mod.mk:
  marlin_VARIANT = ${marlin_VARIANT}
    The release or branch of the Marlin source code to use for the mod.
    If undefined then a default will be used. If using the dev variant
    then valid github credentials are required.
  marlin_MOD_BOARD = ${marlin_MOD_BOARD}
    The CAM controller board.
  marlin_FIRMWARE = ${marlin_FIRMWARE}
    The name of the file produced by the Marlin build to be installed on
    the CAM controller board.

Defined in kits.mk:
  MOD_STAGING_PATH = ${MOD_STAGING_PATH}
    Where the firmare image is staged.

Defines:
  marlin_REPO = ${marlin_REPO}
    The URL of the repo to clone the Marlin source frome.
  marlin_VARIANT = ${marlin_VARIANT}
    The branch to use for building the Marlin firmware.
  marlin_PATH = ${marlin_PATH}
    Where to clone the Marlin source to.
  marlin_CONFIG_REPO = ${marlin_CONFIG_REPO}
    The existing Marlin configurations which can be used as starting point
    for a new mod.
  marlin_CONFIG_PATH = ${marlin_CONFIG_PATH}
    Where to clone the Marlin configurations to.
  ModFirmware = ${ModFirmware}
    The dependencies to build the firmware.

Command line targets:
  help-marlin     Display this help.
  marlin          Install the Marlin source code and PlatformIO.
  firmware        Build the Marlin firware using the mod source files.

Uses:
  platformio.mk
endef

export HelpMarlinMsg
help-marlin:
> @echo "$$HelpMarlinMsg" | less
endif