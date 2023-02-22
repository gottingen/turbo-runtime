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


set(TURBORT_ALL_SRC
        "core/common/common.cc"
        "core/common/common.cc"
        "core/framework/allocator.cc"
        "core/framework/bfc_arena.cc"
        )

turbort_cc_library(
        NAME
        turbort
        SRCS
        ${TURBORT_ALL_SRC}
        COPTS
        ${TURBORT_DEFAULT_COPTS}
        DEPS
        ${TURBORT_DYLINK} ${TURBO_LIBRARIES}
)

if (TURBORT_BUILD_TESTING)

endif (TURBORT_BUILD_TESTING)

