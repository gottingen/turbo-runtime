// Copyright (c) ByteDance Inc. All rights reserved.
// Licensed under the Apache License, Version 2.0

#include "turbort/core/common/common.h"

#include <turbo/base/turbo_module.h>

TURBO_REGISTER_MODULE_INDEX(turbort::kTBRT,"turbo runtime");

namespace turbort {

// Disable stack for now. TODO add it back
std::vector<std::string> GetStackTrace() {
  return {};
}
}  // namespace turbort