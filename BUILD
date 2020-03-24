load("//:toolchain.bzl", "arm_gcc_toolchain")

filegroup(
    name = "all_arm_gcc_files",
    srcs = glob(["wrappers/*"]) + [
        "@gcc_arm_none_eabi//:all_files",
    ],
)

arm_gcc_toolchain()
