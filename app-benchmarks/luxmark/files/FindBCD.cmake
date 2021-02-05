# -*- cmake -*-
# - Find BCD
#
# BCD_FOUND                 Set if OpenVDB is found.
# BCD_INCLUDE_DIR           OpenVDB's include directory
# BCD_LIBRARY_DIR           OpenVDB's library directory
# BCD_<C>_LIBRARY           Specific openvdb library (<C> is upper-case)
# BCD_LIBRARIES             All openvdb libraries
# BCD_MAJOR_VERSION         Major version number
# BCD_MINOR_VERSION         Minor version number
# BCD_PATCH_VERSION         Patch version number
#
# This module read hints about search locations from variables::
#
# BCD_ROOT                  Preferred installtion prefix

FIND_PACKAGE( PackageHandleStandardArgs )

FIND_PATH( BCD_LOCATION include/bcd/core/Denoiser.h
  "$ENV{BCD_ROOT}"
  )

FIND_PACKAGE_HANDLE_STANDARD_ARGS( bcd
  REQUIRED_VARS BCD_LOCATION
  )

IF( BCD_FOUND )
  SET( BCD_INCLUDE_DIR ${BCD_LOCATION}/include
    CACHE PATH "BCD include directory")

  SET( BCD_LIBRARY_DIR ${BCD_LOCATION}/lib
    CACHE PATH "BCD library directory" )

  FIND_LIBRARY( BCD_CORE_LIBRARY bcdcore
    PATHS ${BCD_LIBRARY_DIR}
    NO_DEFAULT_PATH
    NO_SYSTEM_ENVIRONMENT_PATH
    )

  SET( BCD_LIBRARIES "")
  LIST( APPEND BCD_LIBRARIES ${BCD_CORE_LIBRARY} )
#
#  SET( OPENVDB_VERSION_FILE ${BCD_INCLUDE_DIR}/openvdb/version.h )
#
#  FILE( STRINGS "${OPENVDB_VERSION_FILE}" openvdb_major_version_str
#    REGEX "^#define[\t ]+OPENVDB_LIBRARY_MAJOR_VERSION_NUMBER[\t ]+.*")
#  FILE( STRINGS "${OPENVDB_VERSION_FILE}" openvdb_minor_version_str
#    REGEX "^#define[\t ]+OPENVDB_LIBRARY_MINOR_VERSION_NUMBER[\t ]+.*")
#  FILE( STRINGS "${OPENVDB_VERSION_FILE}" openvdb_patch_version_str
#    REGEX "^#define[\t ]+OPENVDB_LIBRARY_PATCH_VERSION_NUMBER[\t ]+.*")
#
#  STRING( REGEX REPLACE "^.*OPENVDB_LIBRARY_MAJOR_VERSION_NUMBER[\t ]+([0-9]*).*$" "\\1"
#    _openvdb_major_version_number "${openvdb_major_version_str}")
#  STRING( REGEX REPLACE "^.*OPENVDB_LIBRARY_MINOR_VERSION_NUMBER[\t ]+([0-9]*).*$" "\\1"
#    _openvdb_minor_version_number "${openvdb_minor_version_str}")
#  STRING( REGEX REPLACE "^.*OPENVDB_LIBRARY_PATCH_VERSION_NUMBER[\t ]+([0-9]*).*$" "\\1"
#    _openvdb_patch_version_number "${openvdb_patch_version_str}")
#
#  SET( OpenVDB_MAJOR_VERSION ${_openvdb_major_version_number}
#    CACHE STRING "OpenVDB major version number" )
#  SET( OpenVDB_MINOR_VERSION ${_openvdb_minor_version_number}
#    CACHE STRING "OpenVDB minor version number" )
#  SET( OpenVDB_PATCH_VERSION ${_openvdb_patch_version_number}
#    CACHE STRING "OpenVDB patch version number" )

ENDIF( BCD_FOUND )
