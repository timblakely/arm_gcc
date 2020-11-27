load("@rules_cc//cc:defs.bzl", "cc_toolchain")
load(
    "@bazel_tools//tools/cpp:cc_toolchain_config_lib.bzl",
    "feature",
    "flag_group",
    "flag_set",
    "tool_path",
)
load(
    "@bazel_tools//tools/build_defs/cc:action_names.bzl",
    _ASSEMBLE_ACTION_NAME = "ASSEMBLE_ACTION_NAME",
    _CLIF_MATCH_ACTION_NAME = "CLIF_MATCH_ACTION_NAME",
    _CPP_COMPILE_ACTION_NAME = "CPP_COMPILE_ACTION_NAME",
    _CPP_HEADER_PARSING_ACTION_NAME = "CPP_HEADER_PARSING_ACTION_NAME",
    _CPP_LINK_DYNAMIC_LIBRARY_ACTION_NAME = "CPP_LINK_DYNAMIC_LIBRARY_ACTION_NAME",
    _CPP_LINK_EXECUTABLE_ACTION_NAME = "CPP_LINK_EXECUTABLE_ACTION_NAME",
    _CPP_LINK_NODEPS_DYNAMIC_LIBRARY_ACTION_NAME = "CPP_LINK_NODEPS_DYNAMIC_LIBRARY_ACTION_NAME",
    _CPP_MODULE_CODEGEN_ACTION_NAME = "CPP_MODULE_CODEGEN_ACTION_NAME",
    _CPP_MODULE_COMPILE_ACTION_NAME = "CPP_MODULE_COMPILE_ACTION_NAME",
    _C_COMPILE_ACTION_NAME = "C_COMPILE_ACTION_NAME",
    _LINKSTAMP_COMPILE_ACTION_NAME = "LINKSTAMP_COMPILE_ACTION_NAME",
    _LTO_BACKEND_ACTION_NAME = "LTO_BACKEND_ACTION_NAME",
    _PREPROCESS_ASSEMBLE_ACTION_NAME = "PREPROCESS_ASSEMBLE_ACTION_NAME",
)

ALL_COMPILE_ACTIONS = [
    _C_COMPILE_ACTION_NAME,
    _CPP_COMPILE_ACTION_NAME,
    _LINKSTAMP_COMPILE_ACTION_NAME,
    _ASSEMBLE_ACTION_NAME,
    _PREPROCESS_ASSEMBLE_ACTION_NAME,
    _CPP_HEADER_PARSING_ACTION_NAME,
    _CPP_MODULE_COMPILE_ACTION_NAME,
    _CPP_MODULE_CODEGEN_ACTION_NAME,
    _CLIF_MATCH_ACTION_NAME,
    _LTO_BACKEND_ACTION_NAME,
]

ALL_LINK_ACTIONS = [
    _CPP_LINK_EXECUTABLE_ACTION_NAME,
    _CPP_LINK_DYNAMIC_LIBRARY_ACTION_NAME,
    _CPP_LINK_NODEPS_DYNAMIC_LIBRARY_ACTION_NAME,
]

C_CPP_COMPILE_ACTIONS = [
    _C_COMPILE_ACTION_NAME,
    _CPP_COMPILE_ACTION_NAME,
]

ALL_CPP_COMPILE_ACTIONS = [
    _CPP_COMPILE_ACTION_NAME,
    _CPP_MODULE_CODEGEN_ACTION_NAME,
    _CPP_HEADER_PARSING_ACTION_NAME,
    _CPP_MODULE_COMPILE_ACTION_NAME,
    _CPP_LINK_EXECUTABLE_ACTION_NAME,
    _CPP_LINK_DYNAMIC_LIBRARY_ACTION_NAME,
    _CPP_LINK_NODEPS_DYNAMIC_LIBRARY_ACTION_NAME,
]

# TODO(blakely): break this out when the toolchain transition is
# released and supported
# https://github.com/bazelbuild/bazel/issues/10523

_BASE_FEATURES = [
    feature(
        name = "static_link_cpp_runtimes",
        # implies = ["no-unused-command-line-argument"], # TODO(blakely)
    ),
    feature(
        name = "deterministic_builds",
        flag_sets = [
            flag_set(
                actions = C_CPP_COMPILE_ACTIONS,  # Should it be all?
                flag_groups = [
                    flag_group(
                        flags = [
                            "-Wno-builtin-macro-redefined",
                            "-D__DATE__=\"redacted\"",
                            "-D__TIMESTAMP__=\"redacted\"",
                            "-D__TIME__=\"redacted\"",
                        ],
                    ),
                ],
            ),
        ],
    ),
    # Disable exceptions
    feature(
        name = "no-exceptions",
        flag_sets = [
            flag_set(
                actions = C_CPP_COMPILE_ACTIONS + ALL_LINK_ACTIONS,
                flag_groups = [
                    flag_group(
                        flags = [
                            "-fno-exceptions",
                        ],
                    ),
                ],
            ),
        ],
    ),
    feature(
        name = "hardening",
        flag_sets = [
            flag_set(
                actions = C_CPP_COMPILE_ACTIONS,
                flag_groups = [
                    flag_group(
                        flags = [
                            "-U_FORTIFY_SOURCE",
                            "-D_FORTIFY_SOURCE=1",
                        ],
                    ),
                ],
            ),
            flag_set(
                actions = [
                    _CPP_LINK_DYNAMIC_LIBRARY_ACTION_NAME,
                    _CPP_LINK_NODEPS_DYNAMIC_LIBRARY_ACTION_NAME,
                    _CPP_LINK_EXECUTABLE_ACTION_NAME,
                ],
                # - Relro is relocation read only for ELF
                # - Now forces dynamic linker to resolve all symbols
                # immediately, not on first load.
                flag_groups = [flag_group(flags = ["-Wl,-z,relro,-z,now"])],
            ),
        ],
    ),
    # Produce dynamic libraries alongside static
    # TODO(blakely): Add support for dynamic linkers if ever building for win
    feature(
        name = "supports_dynamic_linker",
        enabled = False,
    ),
    # Warnings
    feature(
        name = "warnings",
        flag_sets = [
            flag_set(
                actions = C_CPP_COMPILE_ACTIONS,
                flag_groups = [
                    flag_group(
                        flags = [
                            "-Wall",  # Standard
                            "-Wextra",  # Additional
                            "-Wvla",  # Variable length arrays
                        ],
                    ),
                ],
            ),
        ],
    ),
    # Disable assertions
    feature(
        name = "disable-assertions",
        flag_sets = [
            flag_set(
                actions = C_CPP_COMPILE_ACTIONS,
                flag_groups = [flag_group(flags = ["-DNDEBUG"])],
            ),
        ],
    ),
    # Frame pointers,
    feature(
        name = "frame-pointer",
        flag_sets = [
            flag_set(
                actions = C_CPP_COMPILE_ACTIONS,
                flag_groups = [flag_group(flags = ["-fno-omit-frame-pointer"])],
            ),
        ],
    ),
    # Build ID
    feature(
        name = "build-id",
        flag_sets = [
            flag_set(
                actions = ALL_LINK_ACTIONS,
                flag_groups = [
                    flag_group(
                        flags = ["-Wl,--build-id=md5", "-Wl,--hash-style=gnu"],
                    ),
                ],
            ),
        ],
    ),
    # Do not resolve symlinks
    feature(
        name = "no-canonical-prefixes",
        flag_sets = [
            flag_set(
                actions = C_CPP_COMPILE_ACTIONS,
                flag_groups = [
                    flag_group(
                        flags = ["-no-canonical-prefixes"],
                    ),
                ],
            ),
        ],
    ),
    # Do not shorten system header paths
    feature(
        name = "no-canonical-system-headers",
        flag_sets = [
            flag_set(
                actions = C_CPP_COMPILE_ACTIONS,
                flag_groups = [
                    flag_group(
                        flags = ["-fno-canonical-system-headers"],
                    ),
                ],
            ),
        ],
    ),
    # TODO: no stripping
    # TODO: has configured linker path
    # TODO: copy dynamic libraries to binary
    # cpp20 features
    feature(
        name = "cpp20",
        flag_sets = [
            flag_set(
                actions = ALL_CPP_COMPILE_ACTIONS,
                flag_groups = [flag_group(flags = [
                    # c++20 isn't standardized yet, so use gcc's 2a
                    "-std=c++2a",
                ])],
            ),
        ],
    ),
    # Disable RTTI
    feature(
        name = "no-rtti",
        flag_sets = [
            flag_set(
                actions = ALL_CPP_COMPILE_ACTIONS,
                flag_groups = [flag_group(flags = ["-fno-rtti"])],
            ),
        ],
    ),
    # Include stdint
    feature(
        name = "stdint",
        flag_sets = [
            flag_set(
                actions = ALL_CPP_COMPILE_ACTIONS,
                flag_groups = [flag_group(flags = ["-includestdint.h"])],
            ),
        ],
    ),
]

_OPTIONAL_FEATURES = [
    # Optionally make all warnings errors
    feature(
        name = "warnings_are_errors",
        flag_sets = [
            flag_set(
                actions = C_CPP_COMPILE_ACTIONS,
                flag_groups = [
                    flag_group(
                        flags = [
                            "-Werror",  # Make warnings errors.
                        ],
                    ),
                ],
            ),
        ],
        enabled = False,
    ),
    # Optionally dump memory stats
    feature(
        name = "dump_memory_stats",
        flag_sets = [
            flag_set(
                actions = ALL_LINK_ACTIONS,
                flag_groups = [
                    flag_group(
                        flags = [
                            "-Wl,--print-memory-usage",
                        ],
                    ),
                ],
            ),
        ],
        enabled = False,
    ),
]

_ARM_COMMON_FEATURES = [
    # Set up stdlib
    feature(
        name = "stdlib",
        flag_sets = [
            flag_set(
                actions = ALL_LINK_ACTIONS,
                flag_groups = [flag_group(flags = [
                    "-Wl,--start-group",
                    "-lstdc++",
                    "-lsupc++",
                    "-lm",
                    "-lc",
                    "-lgcc",
                    "-lnosys",
                    "-Wl,--end-group",
                    "--specs=nosys.specs",
                ])],
            ),
        ],
    ),
    feature(
        name = "thumb",
        flag_sets = [
            flag_set(
                actions = ALL_COMPILE_ACTIONS + ALL_LINK_ACTIONS,
                flag_groups = [flag_group(flags = [
                    "-mthumb",
                ])],
            ),
        ],
    ),
    feature(
        name = "float_abi",
        flag_sets = [
            flag_set(
                actions = ALL_COMPILE_ACTIONS + ALL_LINK_ACTIONS,
                flag_groups = [flag_group(flags = [
                    "-mfloat-abi=hard",
                ])],
            ),
        ],
    ),
]

_STM32G4_FEATURES = [
    feature(
        name = "stm32g4",
        flag_sets = [
            flag_set(
                actions = ALL_COMPILE_ACTIONS + ALL_LINK_ACTIONS,
                flag_groups = [flag_group(flags = [
                    "-mcpu=cortex-m4",
                    "-mfpu=fpv4-sp-d16",
                ])],
            ),
        ],
        # implies = ["stm32"], # TODO(blakely)
    ),
]

_BUILD_CONFIG = [
    feature(
        name = "common",
        implies = [
            "stdlib",
            "cpp20",
            "deterministic_builds",
            "warnings",
            "no-canonical-prefixes",
            "no-canonical-system-headers",
            "no-rtti",
            "no-exceptions",
            "thumb",
            "float_abi",
            "stm32g4",
            "stdint",
        ],
    ),
    # Build dbg
    feature(
        name = "dbg",
        flag_sets = [
            flag_set(
                # actions = C_CPP_COMPILE_ACTIONS,
                actions = ALL_COMPILE_ACTIONS,
                flag_groups = [flag_group(flags = [
                    "-O0",
                    "-g3",
                ])],
            ),
        ],
        implies = [
            "common",
        ],
    ),
    feature(name = "fastbuild", implies = ["dbg"]),
    feature(
        name = "opt",
        flag_sets = [
            flag_set(
                actions = C_CPP_COMPILE_ACTIONS,
                flag_groups = [
                    flag_group(
                        flags = [
                            "-g",
                            # "-Os",
                            "-O3",
                            "-ffunction-sections",
                            "-fdata-sections",
                        ],
                    ),
                ],
            ),
            flag_set(
                actions = ALL_LINK_ACTIONS,
                flag_groups = [flag_group(flags = ["-Wl,--gc-sections"])],
            ),
        ],
        implies = [
            "common",
        ],
    ),
]

def _impl(ctx):
    features = (_BASE_FEATURES + _OPTIONAL_FEATURES + _ARM_COMMON_FEATURES +
                _STM32G4_FEATURES + _BUILD_CONFIG)

    toolchain_identifier = "local_linux"
    host_system_name = "local"
    target_system_name = "local"

    # required_feature = feature(
    #     name = "common",
    #     implies = required_features,
    # )

    # features += COMMON_FEATURES

    # features.append(required_feature)

    tool_paths = [
        tool_path(name = "gcc", path = "wrappers/arm-none-eabi-gcc"),
        tool_path(name = "ar", path = "wrappers/arm-none-eabi-ar.sh"),
        tool_path(name = "compat-ld", path = "wrappers/arm-none-eabi-ld.sh"),
        tool_path(name = "cpp", path = "wrappers/arm-none-eabi-cpp"),
        tool_path(name = "gcov", path = "wrappers/arm-none-eabi-gcov.sh"),
        tool_path(name = "ld", path = "wrappers/arm-none-eabi-ld.sh"),
        tool_path(name = "nm", path = "wrappers/arm-none-eabi-nm.sh"),
        tool_path(name = "objcopy", path = "wrappers/arm-none-eabi-objcopy.sh"),
        tool_path(name = "objdump", path = "wrappers/arm-none-eabi-objdump.sh"),
        tool_path(name = "strip", path = "wrappers/arm-none-eabi-strip.sh"),
    ]

    return [
        cc_common.create_cc_toolchain_config_info(
            ctx = ctx,
            features = features,
            action_configs = [],
            artifact_name_patterns = [],
            cxx_builtin_include_directories = [],
            toolchain_identifier = toolchain_identifier,
            host_system_name = host_system_name,
            target_system_name = target_system_name,
            target_cpu = "stm32g474",  # target_cpu,
            target_libc = "",  # target_libc,
            compiler = "",  # compiler,
            abi_version = "",  # abi_version,
            abi_libc_version = "",  # abi_libc_version,
            tool_paths = tool_paths,
            make_variables = [],
            builtin_sysroot = None,
            cc_target_os = None,
        ),
    ]

cc_arm_gcc_config = rule(
    implementation = _impl,
    attrs = {},
    provides = [CcToolchainConfigInfo],
)

def arm_gcc_toolchain():
    cc_arm_gcc_config(
        name = "arm_gcc_config",
    )

    cc_toolchain(
        name = "arm_gcc_cc_toolchain",
        all_files = ":all_arm_gcc_files",
        ar_files = ":all_arm_gcc_files",
        as_files = ":all_arm_gcc_files",
        compiler_files = ":all_arm_gcc_files",
        coverage_files = ":all_arm_gcc_files",
        dwp_files = ":all_arm_gcc_files",
        linker_files = ":all_arm_gcc_files",
        objcopy_files = ":all_arm_gcc_files",
        strip_files = ":all_arm_gcc_files",
        supports_param_files = 0,
        toolchain_config = ":arm_gcc_config",
        toolchain_identifier = "arm_gcc",
    )

    native.toolchain(
        name = "arm_gcc_toolchain",
        exec_compatible_with = [
            "@platforms//cpu:x86_64",
            "@platforms//os:linux",
        ],
        target_compatible_with = [
            "@platforms//cpu:armv7",
        ],
        toolchain = ":arm_gcc_cc_toolchain",
        toolchain_type = "@bazel_tools//tools/cpp:toolchain_type",
    )
