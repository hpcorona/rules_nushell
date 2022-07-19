# Copyright 2022 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

"""Providers and rules for the toolchain."""

NuInfo = provider(
  doc = "Information about the nu shell application.",
  fields = ["nu_binary", "is_windows"],
)

def _nu_toolchain_impl(ctx):
  return [
    platform_common.ToolchainInfo(
      nuinfo = NuInfo(
        nu_binary = ctx.attr.binary,
        is_windows = ctx.file.binary.path.endswith(".exe"),
      ),
    ),
  ]

nu_toolchain = rule(
  implementation = _nu_toolchain_impl,
  attrs = {
    "binary": attr.label(
      mandatory = True,
      executable = True,
      cfg = "exec",
      allow_single_file = True,
    ),
  },
)
