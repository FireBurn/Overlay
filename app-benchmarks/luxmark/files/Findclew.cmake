
FIND_PACKAGE( PackageHandleStandardArgs )

FIND_PATH( CLEW_LOCATION include/clew.h
  "$ENV{CLEW_ROOT}"
  )

FIND_PACKAGE_HANDLE_STANDARD_ARGS( clew
  REQUIRED_VARS CLEW_LOCATION
  )

IF( clew_FOUND )
  SET( clew_INCLUDE_DIR ${CLEW_LOCATION}/include
    CACHE PATH "clew include directory")

  SET( clew_LIBRARY_DIR ${CLEW_LOCATION}/lib
    CACHE PATH "clew library directory" )

  FIND_LIBRARY( clew_LIBRARY clew
    PATHS ${clew_LIBRARY_DIR}
    NO_DEFAULT_PATH
    NO_SYSTEM_ENVIRONMENT_PATH
    )

  SET( clew_LIBRARIES "")
  LIST( APPEND clew_LIBRARIES ${clew_LIBRARY} )

ENDIF( clew_FOUND )
