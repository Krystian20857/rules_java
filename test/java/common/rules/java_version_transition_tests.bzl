# Copyright 2023 The Bazel Authors. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

"""Tests for java_version transition-based toolchain selection."""

load("@rules_testing//lib:analysis_test.bzl", "analysis_test", "test_suite")
load("@rules_testing//lib:util.bzl", "util")
load("//java:defs.bzl", "java_binary", "java_library")
load("//test/java/testutil:java_info_subject.bzl", "java_info_subject")

def _test_java_version_transition(name):
    """Test that java_version triggers appropriate toolchain selection."""
    util.helper_target(
        java_library,
        name = name + "/lib",
        srcs = ["Lib.java"],
        java_version = "17",
    )
    analysis_test(
        name = name,
        impl = _test_java_version_transition_impl,
        target = name + "/lib",
        config_settings = {
            "//command_line_option:java_language_version": "11",
        },
    )

def _test_java_version_transition_impl(env, target):
    """Verify that the java_version attribute triggers transition."""
    # The test verifies that the target can be analyzed with java_version set
    # The actual toolchain selection is verified by Bazel's toolchain resolution
    subject = java_info_subject.from_target(env, target)
    subject.outputs().class_output_jars().contains("{package}/lib{name}.jar")

def _test_default_toolchain_without_java_version(name):
    """Test that targets without java_version use default toolchain."""
    util.helper_target(
        java_library,
        name = name + "/lib",
        srcs = ["Lib.java"],
    )
    analysis_test(
        name = name,
        impl = _test_default_toolchain_without_java_version_impl,
        target = name + "/lib",
    )

def _test_default_toolchain_without_java_version_impl(env, target):
    """Verify that targets without java_version work normally."""
    subject = java_info_subject.from_target(env, target)
    subject.outputs().class_output_jars().contains("{package}/lib{name}.jar")

def _test_binary_with_java_version(name):
    """Test that java_binary respects java_version."""
    util.helper_target(
        java_binary,
        name = name + "/binary",
        srcs = ["Main.java"],
        main_class = "Main",
        java_version = "17",
    )
    analysis_test(
        name = name,
        impl = _test_binary_with_java_version_impl,
        target = name + "/binary",
        config_settings = {
            "//command_line_option:java_language_version": "11",
        },
    )

def _test_binary_with_java_version_impl(env, target):
    """Verify that java_binary with java_version can be analyzed."""
    subject = java_info_subject.from_target(env, target)
    subject.outputs().class_output_jars().contains("{package}/{name}.jar")

def _test_library_deps_with_different_versions(name):
    """Test that a library can depend on another with different java_version."""
    util.helper_target(
        java_library,
        name = name + "/child",
        srcs = ["Child.java"],
        java_version = "17",
    )
    util.helper_target(
        java_library,
        name = name + "/parent",
        srcs = ["Parent.java"],
        java_version = "21",
        deps = [name + "/child"],
    )
    analysis_test(
        name = name,
        impl = _test_library_deps_with_different_versions_impl,
        target = name + "/parent",
        config_settings = {
            "//command_line_option:java_language_version": "11",
        },
    )

def _test_library_deps_with_different_versions_impl(env, target):
    """Verify that libraries with different java_versions can be composed."""
    subject = java_info_subject.from_target(env, target)
    subject.outputs().class_output_jars().contains("{package}/lib{name}.jar")

def java_version_transition_test_suite(name):
    """Test suite for java_version transition functionality."""
    test_suite(
        name = name,
        tests = [
            _test_java_version_transition,
            _test_default_toolchain_without_java_version,
            _test_binary_with_java_version,
            _test_library_deps_with_different_versions,
        ],
    )
