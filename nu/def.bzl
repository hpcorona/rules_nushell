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

def _nu_runfiles(ctx, extra_files = [], transitive_files = None):
  transitive_runfiles = []
  for runfiles_attr in (
    ctx.attr.srcs,
    ctx.attr.data,
    ctx.attr.deps,
  ):
    for target in runfiles_attr:
      transitive_runfiles.append(target[DefaultInfo].default_runfiles)
  runfiles = ctx.runfiles(
    files = extra_files + ctx.files.srcs + ctx.files.data,
    transitive_files = transitive_files,
  )
  runfiles = runfiles.merge_all(transitive_runfiles)
  return runfiles

def _nu_module_impl(ctx):
  defaultinfo = DefaultInfo(runfiles = _nu_runfiles(ctx))
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
  (tools, _) = ctx.resolve_tools(tools=[nu.nu_binary])
  tool_binary = tools.to_list()[0]

  template = ctx.file._template_default
  output = ctx.attr.name
  nu_binary_path = tool_binary.short_path
  entry_point_path = ctx.file.entry_point.short_path
  if nu.is_windows:
    template = ctx.file._template_windows
    output = '%s.bat' % ctx.attr.name
    nu_binary_path = nu_binary_path.replace('/', '\\')
    entry_point_path = entry_point_path.replace('/', '\\')

  output_file = ctx.actions.declare_file(output)
  ctx.actions.expand_template(
    template = template,
    output = output_file,
    substitutions = {
      "{nu_binary}": nu_binary_path,
      "{entry_point}": entry_point_path,
      "{workspace_name}": ctx.workspace_name,
    },
    is_executable = True,
  )

  runfiles = _nu_runfiles(
    ctx = ctx,
    extra_files = [ctx.file.entry_point],
    transitive_files = depset([tool_binary]),
  )
  defaultinfo = DefaultInfo(
    executable = output_file,
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
