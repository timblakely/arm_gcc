#!/bin/bash
# Needed to escape the limitation of tool_path being relative to the toolchain's directory
exec external/gcc_arm_none_eabi/bin/arm-none-eabi-strip "$@"
