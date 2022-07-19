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

"""nu_binary and nu_modules rules."""

load("//toolchain:toolchain.bzl", "NuInfo")

NuModuleInfo = provider(
  fields = ['defaultinfo'],
)

def _nu_module_impl(ctx):
  runfiles = ctx.runfiles(files = ctx.files.data + ctx.files.srcs)
  all_targets = ctx.attr.srcs + ctx.attr.data
  runfiles = runfiles.merge_all([
      target[DefaultInfo].default_runfiles
      for target in all_targets
  ])
  runfiles = runfiles.merge_all([
      target[NuModuleInfo].defaultinfo.default_runfiles
      for target in ctx.attr.deps
  ])

  defaultinfo = DefaultInfo(runfiles = runfiles)
  return [
    defaultinfo,
    NuModuleInfo(
      defaultinfo = defaultinfo,
    ),
  ]

nu_module = rule(
  implementation = _nu_module_impl,
  attrs = {
    "srcs": attr.label_list(
      allow_files = True,
      providers = [DefaultInfo],
    ),
    "data": attr.label_list(
      allow_files = True,
      providers = [DefaultInfo],
    ),
    "deps": attr.label_list(
      allow_files = True,
      providers = [DefaultInfo, NuModuleInfo],
    ),
  },
  provides = [DefaultInfo, NuModuleInfo],
)

def _nu_binary_impl(ctx):
  nu = ctx.toolchains["//toolchain:toolchain_type"].nuinfo
  tool, tool_runfiles = ctx.resolve_tools(tools=[nu.nu_binary])
  tool_binary = tool.to_list()[0]

  runfiles = ctx.runfiles(files = [tool_binary, ctx.file.entry_point] + ctx.files.data + ctx.files.srcs)
  all_targets = ctx.attr.srcs + ctx.attr.data
  runfiles = runfiles.merge_all([
      target[DefaultInfo].default_runfiles
      for target in all_targets
  ])
  runfiles = runfiles.merge_all([
      target[NuModuleInfo].defaultinfo.default_runfiles
      for target in ctx.attr.deps
  ])

  template = ctx.file._template_default
  output = ctx.attr.name
  if nu.is_windows:
    template = ctx.file._template_windows
    output = '%s.bat' % ctx.attr.name
  output_file = ctx.actions.declare_file(output)
  ctx.actions.expand_template(
    template = template,
    output = output_file,
    substitutions = {
      "{nu_binary}": tool_binary.short_path,
      "{entry_point}": ctx.file.entry_point.short_path,
    },
    is_executable = True,
  )

  defaultinfo = DefaultInfo(
    executable = output_file,
    files = depset([output_file]),
    runfiles = runfiles,
  )
  return [
    defaultinfo,
    NuModuleInfo(
      defaultinfo = defaultinfo,
    ),
  ]

nu_binary = rule(
  implementation = _nu_binary_impl,
  attrs = {
    "entry_point": attr.label(
      mandatory = True,
      allow_single_file = True,
    ),
    "srcs": attr.label_list(
      allow_files = True,
      providers = [DefaultInfo],
    ),
    "data": attr.label_list(
      allow_files = True,
      providers = [DefaultInfo],
    ),
    "deps": attr.label_list(
      allow_files = True,
      providers = [DefaultInfo, NuModuleInfo],
    ),
    "_template_windows": attr.label(
      allow_single_file = True,
      default = "//nu:gen.nu_binary.windows.bat",
    ),
    "_template_default": attr.label(
      allow_single_file = True,
      default = "//nu:gen.nu_binary.default.sh",
    ),
  },
  executable = True,
  toolchains = [
    "//toolchain:toolchain_type",
  ],
  provides = [DefaultInfo, NuModuleInfo],
)
