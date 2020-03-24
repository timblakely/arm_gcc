load("//:repository.bzl", "local_arm_gcc")

local_arm_gcc("/home/tim/gcc_arm_none_eabi/gcc-arm-none-eabi-9-2019-q4-major")

# arm_gcc_toolchain(
#     local =
#         "/home/tim/gcc_arm_none_eabi/gcc-arm-none-eabi-9-2019-q4-major",
# )

register_toolchains(
    # "@arm_gcc//:arm_gcc_toolchain",
    ":arm_gcc_toolchain",
)
