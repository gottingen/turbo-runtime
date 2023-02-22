"""turbort specific copts.

This file simply selects the correct options from the generated files.  To
change Turbort copts, edit turbort/copts/copts.py
"""

load(
    "//turbort:copts/GENERATED_copts.bzl",
    "TURBORT_CLANG_CL_FLAGS",
    "TURBORT_CLANG_CL_TEST_FLAGS",
    "TURBORT_GCC_FLAGS",
    "TURBORT_GCC_TEST_FLAGS",
    "TURBORT_LLVM_FLAGS",
    "TURBORT_LLVM_TEST_FLAGS",
    "TURBORT_MSVC_FLAGS",
    "TURBORT_MSVC_LINKOPTS",
    "TURBORT_MSVC_TEST_FLAGS",
    "TURBORT_RANDOM_HWAES_ARM32_FLAGS",
    "TURBORT_RANDOM_HWAES_ARM64_FLAGS",
    "TURBORT_RANDOM_HWAES_MSVC_X64_FLAGS",
    "TURBORT_RANDOM_HWAES_X64_FLAGS",
)

TURBORT_DEFAULT_COPTS = select({
    "//turbort:msvc_compiler": TURBORT_MSVC_FLAGS,
    "//turbort:clang-cl_compiler": TURBORT_CLANG_CL_FLAGS,
    "//turbort:clang_compiler": TURBORT_LLVM_FLAGS,
    "//turbort:gcc_compiler": TURBORT_GCC_FLAGS,
    "//conditions:default": TURBORT_GCC_FLAGS,
})

TURBORT_TEST_COPTS = select({
    "//turbort:msvc_compiler": TURBORT_MSVC_TEST_FLAGS,
    "//turbort:clang-cl_compiler": TURBORT_CLANG_CL_TEST_FLAGS,
    "//turbort:clang_compiler": TURBORT_LLVM_TEST_FLAGS,
    "//turbort:gcc_compiler": TURBORT_GCC_TEST_FLAGS,
    "//conditions:default": TURBORT_GCC_TEST_FLAGS,
})

TURBORT_DEFAULT_LINKOPTS = select({
    "//turbort:msvc_compiler": TURBORT_MSVC_LINKOPTS,
    "//conditions:default": [],
})

# TURBORT_RANDOM_RANDEN_COPTS blaze copts flags which are required by each
# environment to build an accelerated RandenHwAes library.
TURBORT_RANDOM_RANDEN_COPTS = select({
    # APPLE
    ":cpu_darwin_x86_64": TURBORT_RANDOM_HWAES_X64_FLAGS,
    ":cpu_darwin": TURBORT_RANDOM_HWAES_X64_FLAGS,
    ":cpu_x64_windows_msvc": TURBORT_RANDOM_HWAES_MSVC_X64_FLAGS,
    ":cpu_x64_windows": TURBORT_RANDOM_HWAES_MSVC_X64_FLAGS,
    ":cpu_k8": TURBORT_RANDOM_HWAES_X64_FLAGS,
    ":cpu_ppc": ["-mcrypto"],
    ":cpu_aarch64": TURBORT_RANDOM_HWAES_ARM64_FLAGS,

    # Supported by default or unsupported.
    "//conditions:default": [],
})

# turbort_random_randen_copts_init:
#  Initialize the config targets based on cpu, os, etc. used to select
#  the required values for TURBORT_RANDOM_RANDEN_COPTS
def turbort_random_randen_copts_init():
    """Initialize the config_settings used by TURBORT_RANDOM_RANDEN_COPTS."""

    # CPU configs.
    # These configs have consistent flags to enable HWAES intsructions.
    cpu_configs = [
        "ppc",
        "k8",
        "darwin_x86_64",
        "darwin",
        "x64_windows_msvc",
        "x64_windows",
        "aarch64",
    ]
    for cpu in cpu_configs:
        native.config_setting(
            name = "cpu_%s" % cpu,
            values = {"cpu": cpu},
        )
