#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# OctoPrint
#----------------------------------------------------------------------------
# The prefix aocp must be unique for all files.
# +++++
# Preamble
ifndef aocpSegId
$(call Enter-Segment,aocp)
# -----

$(call Require,${MOD}.mk,GW_OS GW_OS_VARIANT GW_USER GW_APP)

GW_INIT_SCRIPT = init-octoprint.sh

# Limit to stage-os-image only.
ifeq (${MAKECMDGOALS},stage-os-image)

define octoprint_init_script
# This is designed to be sourced (included) by the first run script. The
# first run script has already sourced the options.sh script.
# This runs as root. OctoPrint is installed as the unprivileged user.
# Following the instructions found at:
#  https://community.octoprint.org/t/setting-up-octoprint-on-a-raspberry-pi-running-raspberry-pi-os-debian/2337

apt update
apt install python3-pip python3-dev python3-setuptools python3-venv
su - ${GW_USER}
mkdir OctoPrint && cd OctoPrint
python3 -m venv venv
. venv/bin/activate
pip install pip --upgrade
pip install octoprint
deactivate
exit
# Back as root.
cp ${${GW_OS_VARIANT}_TMP_PATH}/octoprint.service /etc/systemd/system
systemctl enable octoprint.service

endef

# This was downloaded from:
# https://github.com/OctoPrint/OctoPrint/raw/master/scripts/octoprint.service
define octoprint_service
[Unit]
Description=The snappy web interface for your 3D printer
After=network-online.target
Wants=network-online.target

[Service]
Environment="LC_ALL=C.UTF-8"
Environment="LANG=C.UTF-8"
Type=exec
User=${GW_USER}
ExecStart=/home/${GW_USER}/OctoPrint/venv/bin/octoprint

[Install]
WantedBy=multi-user.target

endef

export octoprint_init_script
export octoprint_service

# This is called by stage-os-image in loi.mk. It generates the runtime
# init script along with the systemd service file for OctoPrint.
define stage_${GW_APP}
  printf "%s" "$$octoprint_init_script" > $(1)/${GW_INIT_SCRIPT}; \
  printf "%s" "$$octoprint_service" > $(1)/octoprint.service
endef

endif

$(call Use-Segment,gw_os/${GW_OS})

# +++++
# Postamble
ifneq ($(call Is-Goal,help-${aocpSeg}),)
define help_${aocpSegN}_msg
Make segment: ${aocpSeg}.mk

This segment is used to install the OctoPrint initialization script in
an OS image for controlling a 3D printer.

Defined in mod.mk:
  GW_APP = ${GW_APP}
    Must equal octoprint for this segment to be used.
  GW_OS = ${GW_OS}
    Which OS is installed on the user interface board (GW_OS_BOARD).

Defined in config.mk:

Defined in ${GW_OS}.mk or a segment it loads:
  OsDeps = ${OsDeps}
    A list of dependencies needed in order to mount an OS image for
    modification.

Defines:
  GW_INIT_SCRIPT = ${GW_INIT_SCRIPT}
    Defines the name of the user interface initialization script which is run in
    a QEMU emulation environment.

Command line goals:
  help-${aocpSeg}   Display this help.
endef
endif # help goal message.

$(call Exit-Segment,aocp)
else # aocpSegId exists
$(call Check-Segment-Conflicts,aocp)
endif # aocpSegId
# -----
