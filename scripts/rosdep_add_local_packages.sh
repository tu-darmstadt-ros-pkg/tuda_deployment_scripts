#!/bin/bash
. $(dirname $0)/helper/globals.sh
. $(dirname $0)/helper/log_output.sh

BASE_PATH=$(readlink -f $(dirname $0)/..)
ROSDEP_EXTRA_YAML_FILE="${BASE_PATH}/rosdep_extra_packages.yaml"

if [[ ! -f $ROSDEP_LIST_FILE ]]; then
  error "Rosdep source file not found. Did you run ${ROSWSS_PREFIX} make_debian_packages_init?"
  exit 1
fi

function add_pkg_to_rosdep() {
    local PKG_NAME=$1
    local DEBIAN_PKG_NAME_PROJECT=$(to_debian_pkg_name "$PKG_NAME")
    create_rosdep_entry "$PKG_NAME" "$DEBIAN_PKG_NAME_PROJECT" >> ${ROSDEP_YAML_FILE}.new
}

function add_local_rosdeps() {
    local FORCE=$1

    # add all local ROS packages from build dir to rosdep
    for PKG_BUILD_PATH in $(catkin --no-color list --unformatted --quiet --workspace ${ROSWSS_ROOT} | sort); do
        local PKG_NAME=$(basename ${PKG_BUILD_PATH})
        add_pkg_to_rosdep ${PKG_NAME}
    done

    if [[ "$FORCE" != "--force" ]]; then
        cmp --silent ${ROSDEP_YAML_FILE}.new ${ROSDEP_YAML_FILE} && {
            rm -rf ${ROSDEP_YAML_FILE}.new
            info "rosdep already up to date."
            exit
        }
    fi

    # add workspace packages to rosdep list and update rosdep cache
    rm -rf ${ROSDEP_YAML_FILE} 2>/dev/null
    mv ${ROSDEP_YAML_FILE}.new ${ROSDEP_YAML_FILE}
    rosdep update
}

add_local_rosdeps $1 || exit $?
