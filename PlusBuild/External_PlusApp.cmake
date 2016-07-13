# --------------------------------------------------------------------------
# PlusApp
SET(PLUSBUILD_SVN_REVISION_ARGS)
IF ( NOT PLUS_SVN_REVISION STREQUAL "0" )
  SET(PLUSBUILD_SVN_REVISION_ARGS 
    SVN_REVISION -r "${PLUS_SVN_REVISION}"
    )
ENDIF()

SET(PLUSBUILD_ADDITIONAL_SDK_ARGS)

IF ( PLUSBUILD_DOCUMENTATION )
  SET(PLUSBUILD_ADDITIONAL_SDK_ARGS ${PLUSBUILD_ADDITIONAL_SDK_ARGS} 
    -DPLUSAPP_DOCUMENTATION_SEARCH_SERVER_INDEXED=${PLUSBUILD_DOCUMENTATION_SEARCH_SERVER_INDEXED}
    -DDOXYGEN_DOT_EXECUTABLE:FILEPATH=${DOXYGEN_DOT_EXECUTABLE}
    -DDOXYGEN_EXECUTABLE:FILEPATH=${DOXYGEN_EXECUTABLE}
    )
ENDIF()

IF( BUILDNAME )
  SET(PLUSBUILD_ADDITIONAL_SDK_ARGS ${PLUSBUILD_ADDITIONAL_SDK_ARGS}
    -DBUILDNAME:STRING=${BUILDNAME}
  )
ENDIF( BUILDNAME )

SET (PLUS_PLUSAPP_DIR ${CMAKE_BINARY_DIR}/PlusApp CACHE INTERNAL "Path to store PlusApp contents.")
SET (PLUSAPP_DIR ${CMAKE_BINARY_DIR}/PlusApp-bin CACHE PATH "The directory containing PlusApp binaries" FORCE)                
ExternalProject_Add(PlusApp
  "${PLUSBUILD_EXTERNAL_PROJECT_CUSTOM_COMMANDS}"
  SOURCE_DIR "${PLUS_PLUSAPP_DIR}" 
  BINARY_DIR "${PLUSAPP_DIR}"
  #--Download step--------------
  SVN_USERNAME ${PLUSBUILD_ASSEMBLA_USERNAME}
  SVN_PASSWORD ${PLUSBUILD_ASSEMBLA_PASSWORD}
  SVN_REPOSITORY https://subversion.assembla.com/svn/plus/trunk/PlusApp
  ${PLUSBUILD_SVN_REVISION_ARGS}
  #--Configure step-------------
  CMAKE_ARGS 
    ${ep_common_args}
    ${ep_qt_args}
    -DPLUS_EXECUTABLE_OUTPUT_PATH:STRING=${PLUS_EXECUTABLE_OUTPUT_PATH}
    -DPLUSLIB_DIR:PATH=${PLUSLIB_DIR}
    -DPLUSAPP_OFFLINE_BUILD:BOOL=${PLUSBUILD_OFFLINE_BUILD}
    -DSubversion_SVN_EXECUTABLE:FILEPATH=${Subversion_SVN_EXECUTABLE}
    -DPLUSAPP_BUILD_DiagnosticTools:BOOL=ON
    -DPLUSAPP_BUILD_fCal:BOOL=ON
    -DPLUSAPP_TEST_GUI:BOOL=${PLUSAPP_TEST_GUI}
    -DBUILD_DOCUMENTATION:BOOL=${PLUSBUILD_DOCUMENTATION}
    -DPLUSAPP_PACKAGE_EDITION:STRING=${PLUSAPP_PACKAGE_EDITION}
    -DCMAKE_CXX_FLAGS:STRING=${ep_common_cxx_flags}
    -DCMAKE_C_FLAGS:STRING=${ep_common_c_flags}
    ${PLUSBUILD_ADDITIONAL_SDK_ARGS}
  #--Build step-----------------
  BUILD_ALWAYS 1
  #--Install step-----------------
  INSTALL_COMMAND ""
  DEPENDS ${PlusApp_DEPENDENCIES}
  )

# --------------------------------------------------------------------------
# Copy Qt binaries to PLUS_EXECUTABLE_OUTPUT_PATH

# Determine shared library extension without the dot (dll instead of .dll)
STRING(SUBSTRING ${CMAKE_SHARED_LIBRARY_SUFFIX} 1 -1 CMAKE_SHARED_LIBRARY_SUFFIX_NO_SEPARATOR)

# Get all Qt shared library names
IF( ${QT_VERSION_MAJOR} AND ${QT_VERSION_MAJOR} EQUAL 5 )
  SET(RELEASE_REGEX_PATTERN .t5.*[^d][.]${CMAKE_SHARED_LIBRARY_SUFFIX_NO_SEPARATOR})
  SET(DEBUG_REGEX_PATTERN .t5.*d[.]${CMAKE_SHARED_LIBRARY_SUFFIX_NO_SEPARATOR})
ELSE()
  SET(RELEASE_REGEX_PATTERN .*[^d]4[.]${CMAKE_SHARED_LIBRARY_SUFFIX_NO_SEPARATOR} )
  SET(DEBUG_REGEX_PATTERN .*d4[.]${CMAKE_SHARED_LIBRARY_SUFFIX_NO_SEPARATOR} )
ENDIF()

# Copy shared libraries to bin directory to allow running Plus applications in the build tree
IF ( ${CMAKE_GENERATOR} MATCHES "Visual Studio" OR ${CMAKE_GENERATOR} MATCHES "Xcode" )
  FILE(COPY "${QT_BINARY_DIR}/"
    DESTINATION ${PLUS_EXECUTABLE_OUTPUT_PATH}/Release
    FILES_MATCHING REGEX ${RELEASE_REGEX_PATTERN}
    )
  FILE(COPY "${QT_BINARY_DIR}/"
    DESTINATION ${PLUS_EXECUTABLE_OUTPUT_PATH}/Debug
    FILES_MATCHING REGEX ${DEBUG_REGEX_PATTERN}
    )
ELSE()
  FILE(COPY "${QT_BINARY_DIR}/"
    DESTINATION ${PLUS_EXECUTABLE_OUTPUT_PATH}
    FILES_MATCHING REGEX .*${CMAKE_SHARED_LIBRARY_SUFFIX}
    )
ENDIF()
