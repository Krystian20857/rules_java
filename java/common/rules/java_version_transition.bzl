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

"""Configuration transition for per-target Java version selection."""

def _java_version_transition_impl(settings, attr):
    """Transition implementation that sets the Java language version.

    This allows different Java targets to be compiled with different toolchains
    by changing the --java_language_version configuration flag, which triggers
    Bazel's standard toolchain resolution to select the appropriate java_toolchain.

    Args:
        settings: A dictionary of current configuration settings
        attr: The attributes of the rule being transitioned

    Returns:
        A dictionary of configuration settings to change
    """
    if hasattr(attr, "java_version") and attr.java_version:
        return {"//command_line_option:java_language_version": attr.java_version}
    return {}

java_version_transition = transition(
    implementation = _java_version_transition_impl,
    inputs = [],
    outputs = ["//command_line_option:java_language_version"],
)
