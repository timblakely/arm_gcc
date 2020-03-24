def local_arm_gcc(local_path):
    native.new_local_repository(
        name = "gcc_arm_none_eabi",
        path = local_path,
        build_file = "//:gcc_arm_none_eabi.BUILD",
    )
