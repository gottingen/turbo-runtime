#
# Copyright 2020 The Turbort Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# https://github.com/google/oss-policies-info/blob/main/foundational-cxx-support-matrix.md
# As of 2022-09-06, CMake 3.10 is the minimum supported version.
cmake_minimum_required(VERSION 3.10)

# Compiler id for Apple Clang is now AppleClang.
if (POLICY CMP0025)
  cmake_policy(SET CMP0025 NEW)
endif (POLICY CMP0025)

# if command can use IN_LIST
if (POLICY CMP0057)
  cmake_policy(SET CMP0057 NEW)
endif (POLICY CMP0057)

# Project version variables are the empty string if version is unspecified
if (POLICY CMP0048)
  cmake_policy(SET CMP0048 NEW)
endif (POLICY CMP0048)

# option() honor variables
if (POLICY CMP0077)
  cmake_policy(SET CMP0077 NEW)
endif (POLICY CMP0077)

# Allow the user to specify the MSVC runtime
if (POLICY CMP0091)
  cmake_policy(SET CMP0091 NEW)
endif (POLICY CMP0091)

# try_compile() honors the CMAKE_CXX_STANDARD value
if (POLICY CMP0067)
  cmake_policy(SET CMP0067 NEW)
endif (POLICY CMP0067)

if (POLICY CMP0110)
  cmake_policy(SET CMP0110 NEW)
endif (POLICY CMP0110)

project(turbort LANGUAGES CXX)
include(CTest)

# Output directory is correct by default for most build setups. However, when
# building Turbort as a DLL, it is important to have the DLL in the same
# directory as the executable using it. Thus, we put all executables in a single
# /bin directory.
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)

# when turbort is included as subproject (i.e. using add_subdirectory(abseil-cpp))
# in the source tree of a project that uses it, install rules are disabled.
if(NOT CMAKE_SOURCE_DIR STREQUAL PROJECT_SOURCE_DIR)
  option(TURBORT_ENABLE_INSTALL "Enable install rule" OFF)
else()
  option(TURBORT_ENABLE_INSTALL "Enable install rule" ON)
endif()

set(CMAKE_CXX_STANDARD 14)

option(TURBORT_USE_SYSTEM_INCLUDES
  "Silence warnings in Turbort headers by marking them as SYSTEM includes"
  OFF)

list(APPEND CMAKE_MODULE_PATH
  ${CMAKE_CURRENT_LIST_DIR}/CMake
  ${CMAKE_CURRENT_LIST_DIR}/copts
)

include(CMakePackageConfigHelpers)
include(GNUInstallDirs)
include(TurbortHelpers)


##
## Using turbort targets
##
## all public turbort targets are
## exported with the turbort:: prefix
##
## e.g turbort::turbort
##
## DO NOT rely on the internal targets outside of the prefix


# include current path
list(APPEND TURBORT_COMMON_INCLUDE_DIRS ${CMAKE_CURRENT_SOURCE_DIR})

if("${CMAKE_CXX_COMPILER_ID}" MATCHES "Clang")
  set(TURBORT_USING_CLANG ON)
else()
  set(TURBORT_USING_CLANG OFF)
endif()

# find dependencies
## pthread
find_package(Threads REQUIRED)

include(CMakeDependentOption)

option(TURBORT_BUILD_TESTING
  "If ON, Turbort will build all of Turbort's own tests." ON)

option(TURBORT_BUILD_TEST_HELPERS
  "If ON, Turbort will build libraries that you can use to write tests against Turbort code. This option requires that Turbort is configured to use GoogleTest."
  OFF)

option(TURBORT_USE_EXTERNAL_GOOGLETEST
  "If ON, Turbort will assume that the targets for GoogleTest are already provided by the including project. This makes sense when Turbort is used with add_subdirectory." OFF)

cmake_dependent_option(TURBORT_FIND_GOOGLETEST
  "If ON, Turbort will use find_package(GTest) rather than assuming that GoogleTest is already provided by the including project."
  ON
  "TURBORT_USE_EXTERNAL_GOOGLETEST"
  OFF)


option(TURBORT_USE_GOOGLETEST_HEAD
  "If ON, abseil will download HEAD from GoogleTest at config time." ON)

set(TURBORT_GOOGLETEST_DOWNLOAD_URL "" CACHE STRING "If set, download GoogleTest from this URL")

set(TURBORT_LOCAL_GOOGLETEST_DIR "/usr/src/googletest" CACHE PATH
  "If TURBORT_USE_GOOGLETEST_HEAD is OFF and TURBORT_GOOGLETEST_URL is not set, specifies the directory of a local GoogleTest checkout."
  )

if((BUILD_TESTING AND TURBORT_BUILD_TESTING) OR TURBORT_BUILD_TEST_HELPERS)
  if (TURBORT_USE_EXTERNAL_GOOGLETEST)
    if (TURBORT_FIND_GOOGLETEST)
      find_package(GTest REQUIRED)
    elseif(NOT TARGET GTest::gtest)
      if(TARGET gtest)
        # When Google Test is included directly rather than through find_package, the aliases are missing.
        add_library(GTest::gtest ALIAS gtest)
        add_library(GTest::gtest_main ALIAS gtest_main)
        add_library(GTest::gmock ALIAS gmock)
        add_library(GTest::gmock_main ALIAS gmock_main)
      else()
        message(FATAL_ERROR "TURBORT_USE_EXTERNAL_GOOGLETEST is ON and TURBORT_FIND_GOOGLETEST is OFF, which means that the top-level project must build the Google Test project. However, the target gtest was not found.")
      endif()
    endif()
  else()
    set(turbort_gtest_build_dir ${CMAKE_BINARY_DIR}/googletest-build)
    if(TURBORT_USE_GOOGLETEST_HEAD AND TURBORT_GOOGLETEST_DOWNLOAD_URL)
      message(FATAL_ERROR "Do not set both TURBORT_USE_GOOGLETEST_HEAD and TURBORT_GOOGLETEST_DOWNLOAD_URL")
    endif()
    if(TURBORT_USE_GOOGLETEST_HEAD)
      set(turbort_gtest_download_url "https://gitee.com/gottingen/googletest/repository/archive/main.zip")
    elseif(TURBORT_GOOGLETEST_DOWNLOAD_URL)
      set(turbort_gtest_download_url ${TURBORT_GOOGLETEST_DOWNLOAD_URL})
    endif()
    if(turbort_gtest_download_url)
      set(turbort_gtest_src_dir ${CMAKE_BINARY_DIR}/googletest-src)
    else()
      set(turbort_gtest_src_dir ${TURBORT_LOCAL_GOOGLETEST_DIR})
    endif()
    include(CMake/Googletest/DownloadGTest.cmake)
  endif()
endif()

set(TURBORT_DYLINK)
if (APPLE)
  find_library(CoreFoundation CoreFoundation)
  list(APPEND TURBORT_DYLINK ${CoreFoundation} pthread)
elseif (${CMAKE_SYSTEM_NAME} STREQUAL "Linux")
  list(APPEND TURBORT_DYLINK rt dl pthread)
endif ()

find_package(Turbo REQUIRED)
include_directories(${TURBO_INCLUDE_DIR})
add_subdirectory(turbort)

if(TURBORT_ENABLE_INSTALL)
  # turbort:lts-remove-begin(system installation is supported for LTS releases)
  # We don't support system-wide installation
  list(APPEND SYSTEM_INSTALL_DIRS "/usr/local" "/usr" "/opt/" "/opt/local" "c:/Program Files/${PROJECT_NAME}")
  if(NOT DEFINED CMAKE_INSTALL_PREFIX OR CMAKE_INSTALL_PREFIX IN_LIST SYSTEM_INSTALL_DIRS)
    message(WARNING "\
  The default and system-level install directories are unsupported except in LTS \
  releases of Turbort.  Please set CMAKE_INSTALL_PREFIX to install Turbort in your \
  source or build tree directly.\
    ")
  endif()
  # turbort:lts-remove-end

  # install as a subdirectory only
  install(EXPORT ${PROJECT_NAME}Targets
    NAMESPACE turbort::
    DESTINATION "${CMAKE_INSTALL_LIBDIR}/cmake/${PROJECT_NAME}"
  )

  configure_package_config_file(
    CMake/turbortConfig.cmake.in
    "${PROJECT_BINARY_DIR}/${PROJECT_NAME}Config.cmake"
    INSTALL_DESTINATION "${CMAKE_INSTALL_LIBDIR}/cmake/${PROJECT_NAME}"
  )
  install(FILES "${PROJECT_BINARY_DIR}/${PROJECT_NAME}Config.cmake"
    DESTINATION "${CMAKE_INSTALL_LIBDIR}/cmake/${PROJECT_NAME}"
  )

  # Turbort only has a version in LTS releases.  This mechanism is accomplished
  # Turbort's internal Copybara (https://github.com/google/copybara) workflows and
  # isn't visible in the CMake buildsystem itself.
  if(turbort_VERSION)
    write_basic_package_version_file(
      "${PROJECT_BINARY_DIR}/${PROJECT_NAME}ConfigVersion.cmake"
      COMPATIBILITY ExactVersion
    )

    install(FILES "${PROJECT_BINARY_DIR}/${PROJECT_NAME}ConfigVersion.cmake"
      DESTINATION "${CMAKE_INSTALL_LIBDIR}/cmake/${PROJECT_NAME}"
    )
  endif()  # turbort_VERSION

  install(DIRECTORY turbort
    DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
    FILES_MATCHING
      PATTERN "*.inc"
      PATTERN "*.h"
      PATTERN "copts" EXCLUDE
      PATTERN "testdata" EXCLUDE
    )
endif()  # TURBORT_ENABLE_INSTALL
