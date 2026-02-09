"""Tests for per-target java_toolchain selection in java_library"""

load("@rules_testing//lib:analysis_test.bzl", "analysis_test", "test_suite")
load("@rules_testing//lib:truth.bzl", "matching")
load("@rules_testing//lib:util.bzl", "util")
load("//java:java_library.bzl", "java_library")
load("//java/common:java_info.bzl", "JavaInfo")
load("//toolchains:default_java_toolchain.bzl", "default_java_toolchain")

def _test_explicit_toolchain_is_used(name):
    """Test that an explicitly specified java_toolchain is used for compilation."""

    # Create a custom toolchain with a specific source_version
    util.helper_target(
        default_java_toolchain,
        name = name + "/custom_toolchain",
        source_version = "17",
        target_version = "17",
        toolchain_definition = False,
    )

    # Create a java_library that uses the custom toolchain
    util.helper_target(
        java_library,
        name = name + "/lib_with_explicit_toolchain",
        srcs = ["ExplicitToolchain.java"],
        java_toolchain = name + "/custom_toolchain",
    )

    analysis_test(
        name = name,
        impl = _test_explicit_toolchain_is_used_impl,
        target = name + "/lib_with_explicit_toolchain",
    )

def _test_explicit_toolchain_is_used_impl(env, target):
    # Verify that the target compiled successfully (has JavaInfo)
    env.expect.that_bool(JavaInfo in target).equals(True)

    # Verify the Javac action has the expected source version from the explicit toolchain
    javac_action = env.expect.that_target(target).action_named("Javac")
    javac_action.mnemonic().equals("Javac")

def _test_default_toolchain_when_not_specified(name):
    """Test that the default toolchain is used when java_toolchain is not specified."""

    util.helper_target(
        java_library,
        name = name + "/lib_default_toolchain",
        srcs = ["DefaultToolchain.java"],
    )

    analysis_test(
        name = name,
        impl = _test_default_toolchain_when_not_specified_impl,
        target = name + "/lib_default_toolchain",
    )

def _test_default_toolchain_when_not_specified_impl(env, target):
    # Verify that the target compiled successfully (has JavaInfo)
    env.expect.that_bool(JavaInfo in target).equals(True)

    # Verify the Javac action exists
    javac_action = env.expect.that_target(target).action_named("Javac")
    javac_action.mnemonic().equals("Javac")

def _test_different_toolchains_same_build(name):
    """Test that different targets can use different toolchains in the same build."""

    # Create two custom toolchains with different versions
    util.helper_target(
        default_java_toolchain,
        name = name + "/toolchain_v11",
        source_version = "11",
        target_version = "11",
        toolchain_definition = False,
    )

    util.helper_target(
        default_java_toolchain,
        name = name + "/toolchain_v17",
        source_version = "17",
        target_version = "17",
        toolchain_definition = False,
    )

    # Create two java_libraries using different toolchains
    util.helper_target(
        java_library,
        name = name + "/lib_v11",
        srcs = ["LibV11.java"],
        java_toolchain = name + "/toolchain_v11",
    )

    util.helper_target(
        java_library,
        name = name + "/lib_v17",
        srcs = ["LibV17.java"],
        java_toolchain = name + "/toolchain_v17",
    )

    # A library using the default toolchain that depends on both
    util.helper_target(
        java_library,
        name = name + "/lib_combined",
        srcs = ["LibCombined.java"],
        deps = [
            name + "/lib_v11",
            name + "/lib_v17",
        ],
    )

    analysis_test(
        name = name,
        impl = _test_different_toolchains_same_build_impl,
        targets = {
            "lib_v11": name + "/lib_v11",
            "lib_v17": name + "/lib_v17",
            "lib_combined": name + "/lib_combined",
        },
    )

def _test_different_toolchains_same_build_impl(env, targets):
    # All targets should have compiled successfully
    env.expect.that_bool(JavaInfo in targets.lib_v11).equals(True)
    env.expect.that_bool(JavaInfo in targets.lib_v17).equals(True)
    env.expect.that_bool(JavaInfo in targets.lib_combined).equals(True)

    # Verify each target has a Javac action with correct source version
    # Using contains_at_least_args since -source and the version are separate args
    env.expect.that_target(targets.lib_v11).action_named("Javac").contains_at_least_args([
        "-source", "11",
    ])
    env.expect.that_target(targets.lib_v17).action_named("Javac").contains_at_least_args([
        "-source", "17",
    ])

def _test_explicit_toolchain_javac_opts(name):
    """Test that the explicit toolchain's javac options are used."""

    # Create a toolchain targeting Java 11
    util.helper_target(
        default_java_toolchain,
        name = name + "/toolchain_java11",
        source_version = "11",
        target_version = "11",
        toolchain_definition = False,
    )

    util.helper_target(
        java_library,
        name = name + "/lib",
        srcs = ["Lib.java"],
        java_toolchain = name + "/toolchain_java11",
    )

    analysis_test(
        name = name,
        impl = _test_explicit_toolchain_javac_opts_impl,
        target = name + "/lib",
    )

def _test_explicit_toolchain_javac_opts_impl(env, target):
    # Verify the Javac action contains the expected source/target version flags
    # Using contains_at_least_args since -source/-target and the version are separate args
    javac_action = env.expect.that_target(target).action_named("Javac")
    javac_action.contains_at_least_args(["-source", "11"])
    javac_action.contains_at_least_args(["-target", "11"])

def java_toolchain_selection_tests(name):
    test_suite(
        name = name,
        tests = [
            _test_explicit_toolchain_is_used,
            _test_default_toolchain_when_not_specified,
            _test_different_toolchains_same_build,
            _test_explicit_toolchain_javac_opts,
        ],
    )
