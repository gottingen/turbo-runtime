// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.
// ===========================================================================
// Modifications Copyright (c) ByteDance.

#pragma once

#include <string.h>
#include <sstream>
#include <string>

/**
 * memory types for allocator, exec provider specific types should be extended in each provider
 * Whenever this struct is updated, please also update the MakeKey function in
 * onnxruntime/core/framework/execution_provider.cc
 */
typedef enum TbrtMemType {
  TbrtMemTypeCPUInput = -2,  // Any CPU memory used by non-CPU execution provider
  TbrtMemTypeCPUOutput =
      -1,  // CPU accessible memory outputted by non-CPU execution provider, i.e. CUDA_PINNED
  TbrtMemTypeCPU = TbrtMemTypeCPUOutput,  // temporary CPU accessible memory allocated by non-CPU
                                        // execution provider, i.e. CUDA_PINNED
  TbrtMemTypeDefault = 0,                // the default allocator for execution provider
} TbrtMemType;

typedef enum TbrtAllocatorType {
  Invalid = -1,
  TbrtDeviceAllocator = 0,
  TbrtArenaAllocator = 1
} TbrtAllocatorType;

struct TbrtMemoryInfo {
  TbrtMemoryInfo() = default;  // to allow default construction of Tensor

  // use string for name, so we could have customized allocator in execution provider.
  const char* name = nullptr;
  int id = -1;
  TbrtMemType mem_type = TbrtMemTypeDefault;
  TbrtAllocatorType alloc_type = Invalid;

  constexpr TbrtMemoryInfo(const char* name_,
                          TbrtAllocatorType type_,
                          int id_ = 0,
                          TbrtMemType mem_type_ = TbrtMemTypeDefault)
#if ((defined(__GNUC__) && __GNUC__ > 4) || defined(__clang__))
      // this causes a spurious error in CentOS gcc 4.8 build so disable if GCC version < 5
      __attribute__((nonnull))
#endif
      : name(name_), id(id_), mem_type(mem_type_), alloc_type(type_) {
  }

  // To make OrtMemoryInfo become a valid key in std map
  bool operator<(const TbrtMemoryInfo& other) const {
    if (alloc_type != other.alloc_type)
      return alloc_type < other.alloc_type;
    if (mem_type != other.mem_type)
      return mem_type < other.mem_type;
    if (id != other.id)
      return id < other.id;

    return strcmp(name, other.name) < 0;
  }

  std::string ToString() const {
    std::ostringstream ostr;
    ostr << "TbrtMemoryInfo:["
         << "name:" << name << " id:" << id << " TbrtMemType:" << mem_type
         << " TbrtAllocatorType:" << alloc_type << "]";
    return ostr.str();
  }
};

inline bool operator==(const TbrtMemoryInfo& left, const TbrtMemoryInfo& other) {
  return left.mem_type == other.mem_type && left.alloc_type == other.alloc_type &&
         left.id == other.id && strcmp(left.name, other.name) == 0;
}

inline bool operator!=(const TbrtMemoryInfo& lhs, const TbrtMemoryInfo& rhs) {
  return !(lhs == rhs);
}

std::ostream& operator<<(std::ostream& out, const TbrtMemoryInfo& info);
