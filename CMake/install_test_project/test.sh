#!/bin/bash
#
# Copyright 2019 The Turbort Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# Unit and integration tests for Turbort LTS CMake installation

# Fail on any error. Treat unset variables an error. Print commands as executed.
set -euox pipefail

turbort_dir=/abseil-cpp
turbort_build_dir=/buildfs
googletest_builddir=/googletest_builddir
project_dir="${turbort_dir}"/CMake/install_test_project
project_build_dir=/buildfs/project-build

build_shared_libs="OFF"
if [ "${LINK_TYPE:-}" = "DYNAMIC" ]; then
  build_shared_libs="ON"
fi

# Build and install GoogleTest
mkdir "${googletest_builddir}"
pushd "${googletest_builddir}"
curl -L "${TURBORT_GOOGLETEST_DOWNLOAD_URL}" --output "${TURBORT_GOOGLETEST_COMMIT}".zip
unzip "${TURBORT_GOOGLETEST_COMMIT}".zip
pushd "googletest-${TURBORT_GOOGLETEST_COMMIT}"
mkdir build
pushd build
cmake -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS="${build_shared_libs}" ..
make -j $(nproc)
make install
ldconfig
popd
popd
popd

# Run the LTS transformations
./create_lts.py 99998877

# Build and install Turbort
pushd "${turbort_build_dir}"
cmake "${turbort_dir}" \
  -DTURBORT_USE_EXTERNAL_GOOGLETEST=ON \
  -DTURBORT_FIND_GOOGLETEST=ON  \
  -DCMAKE_BUILD_TYPE=Release \
  -DTURBORT_BUILD_TESTING=ON \
  -DBUILD_SHARED_LIBS="${build_shared_libs}"
make -j $(nproc)
ctest -j $(nproc) --output-on-failure
make install
ldconfig
popd

# Test the project against the installed Turbort
mkdir -p "${project_build_dir}"
pushd "${project_build_dir}"
cmake "${project_dir}"
cmake --build . --target simple

output="$(${project_build_dir}/simple "printme" 2>&1)"
if [[ "${output}" != *"Arg 1: printme"* ]]; then
  echo "Faulty output on simple project:"
  echo "${output}"
  exit 1
fi

popd

if ! grep turbort::strings "/usr/local/lib/cmake/turbort/turbortTargets.cmake"; then
  cat "/usr/local/lib/cmake/turbort/turbortTargets.cmake"
  echo "CMake targets named incorrectly"
  exit 1
fi

pushd "${HOME}"
cat > hello-abseil.cc << EOF
#include <cstdlib>

#include "turbort/strings/str_format.h"

int main(int argc, char **argv) {
  turbort::PrintF("Hello Turbort!\n");
  return EXIT_SUCCESS;
}
EOF

if [ "${LINK_TYPE:-}" != "DYNAMIC" ]; then
  pc_args=($(pkg-config --cflags --libs --static turbort_str_format))
  g++ -static -o hello-abseil hello-abseil.cc "${pc_args[@]}"
else
  pc_args=($(pkg-config --cflags --libs turbort_str_format))
  g++ -o hello-abseil hello-abseil.cc "${pc_args[@]}"
fi
hello="$(./hello-abseil)"
[[ "${hello}" == "Hello Turbort!" ]]

popd

echo "Install test complete!"
exit 0
