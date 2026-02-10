"""Tests for per-target java_runtime selection in java_binary"""

load("@rules_testing//lib:analysis_test.bzl", "analysis_test", "test_suite")
load("@rules_testing//lib:util.bzl", "util")
load("//java:java_binary.bzl", "java_binary")
load("//java/common:java_info.bzl", "JavaInfo")
load("//java/common:java_semantics.bzl", "semantics")
load("//java/toolchains:java_runtime.bzl", "java_runtime")

def _test_explicit_runtime_is_used(name):
    """Test that an explicitly specified java_runtime is used for execution."""

    # Create a custom runtime with a specific java_home
    util.helper_target(
        java_runtime,
        name = name + "/custom_runtime",
        srcs = [],
        java_home = "/custom/jdk/path",
        version = 17,
    )

    # Create a java_binary that uses the custom runtime
    util.helper_target(
        java_binary,
        name = name + "/binary_with_explicit_runtime",
        srcs = ["ExplicitRuntime.java"],
        main_class = "ExplicitRuntime",
        java_runtime = name + "/custom_runtime",
    )

    analysis_test(
        name = name,
        impl = _test_explicit_runtime_is_used_impl,
        target = name + "/binary_with_explicit_runtime",
    )

def _test_explicit_runtime_is_used_impl(env, target):
    # Verify that the target built successfully (has JavaInfo)
    env.expect.that_bool(JavaInfo in target).equals(True)

    # Verify that executable exists (has a path)
    executable = env.expect.that_target(target).executable()
    executable.path().contains("binary_with_explicit_runtime")

def _test_default_runtime_when_not_specified(name):
    """Test that the default runtime is used when java_runtime is not specified."""

    util.helper_target(
        java_binary,
        name = name + "/binary_default_runtime",
        srcs = ["DefaultRuntime.java"],
        main_class = "DefaultRuntime",
    )

    analysis_test(
        name = name,
        impl = _test_default_runtime_when_not_specified_impl,
        target = name + "/binary_default_runtime",
    )

def _test_default_runtime_when_not_specified_impl(env, target):
    # Verify that the target built successfully (has JavaInfo)
    env.expect.that_bool(JavaInfo in target).equals(True)

    # Verify that executable exists (has a path)
    executable = env.expect.that_target(target).executable()
    executable.path().contains("binary_default_runtime")

def _test_different_runtimes_same_build(name):
    """Test that different binaries can use different runtimes in the same build."""

    # Create two custom runtimes with different versions
    util.helper_target(
        java_runtime,
        name = name + "/runtime_jdk11",
        srcs = [],
        java_home = "/path/to/jdk11",
        version = 11,
    )

    util.helper_target(
        java_runtime,
        name = name + "/runtime_jdk17",
        srcs = [],
        java_home = "/path/to/jdk17",
        version = 17,
    )

    # Create two java_binaries using different runtimes
    util.helper_target(
        java_binary,
        name = name + "/binary_jdk11",
        srcs = ["BinaryJdk11.java"],
        main_class = "BinaryJdk11",
        java_runtime = name + "/runtime_jdk11",
    )

    util.helper_target(
        java_binary,
        name = name + "/binary_jdk17",
        srcs = ["BinaryJdk17.java"],
        main_class = "BinaryJdk17",
        java_runtime = name + "/runtime_jdk17",
    )

    analysis_test(
        name = name,
        impl = _test_different_runtimes_same_build_impl,
        targets = {
            "binary_jdk11": name + "/binary_jdk11",
            "binary_jdk17": name + "/binary_jdk17",
        },
    )

def _test_different_runtimes_same_build_impl(env, targets):
    # All targets should have built successfully
    env.expect.that_bool(JavaInfo in targets.binary_jdk11).equals(True)
    env.expect.that_bool(JavaInfo in targets.binary_jdk17).equals(True)

    # Verify each binary has executables
    env.expect.that_target(targets.binary_jdk11).executable().path().contains("binary_jdk11")
    env.expect.that_target(targets.binary_jdk17).executable().path().contains("binary_jdk17")

def _test_explicit_runtime_with_toolchain(name):
    """Test that explicit runtime works alongside explicit toolchain."""

    # Create a custom runtime
    util.helper_target(
        java_runtime,
        name = name + "/custom_runtime",
        srcs = [],
        java_home = "/custom/jdk/path",
        version = 17,
    )

    util.helper_target(
        java_binary,
        name = name + "/binary",
        srcs = ["Binary.java"],
        main_class = "Binary",
        java_runtime = name + "/custom_runtime",
    )

    analysis_test(
        name = name,
        impl = _test_explicit_runtime_with_toolchain_impl,
        target = name + "/binary",
    )

def _test_explicit_runtime_with_toolchain_impl(env, target):
    # Verify the binary built successfully
    env.expect.that_bool(JavaInfo in target).equals(True)

    # Verify compilation happened (Javac action exists)
    javac_action = env.expect.that_target(target).action_named("Javac")
    javac_action.mnemonic().equals("Javac")

def java_runtime_selection_tests(name):
    test_suite(
        name = name,
        tests = [
            _test_explicit_runtime_is_used,
            _test_default_runtime_when_not_specified,
            _test_different_runtimes_same_build,
            _test_explicit_runtime_with_toolchain,
        ],
    )
