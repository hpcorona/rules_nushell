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

def _nu_runfiles(ctx):
  transitive_runfiles = []
  entry_point = []
  entry_point_file = []
  if hasattr(ctx.attr, 'entry_point'):
    entry_point = [ctx.attr.entry_point]
    entry_point_file = ctx.files.entry_point
  for runfiles_attr in (
    entry_point,
    ctx.attr.srcs,
    ctx.attr.data,
  ):
    for target in runfiles_attr:
      transitive_runfiles.append(target[DefaultInfo].data_runfiles)
      transitive_runfiles.append(target[DefaultInfo].default_runfiles)
  for target in ctx.attr.deps:
    transitive_runfiles.append(target[NuModuleInfo].defaultinfo.data_runfiles)
    transitive_runfiles.append(target[NuModuleInfo].defaultinfo.default_runfiles)
  runfiles = ctx.runfiles(
    files = entry_point_file + ctx.files.srcs + ctx.files.data,
  )
  runfiles = runfiles.merge_all([r for r in transitive_runfiles if r != None])
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
  nu = ctx.toolchains["//toolchain:toolchain_type"].info

  entry_point_path = ctx.file.entry_point.short_path.replace('/', nu.sep)
  output_file = nu.nu_runner(
    ctx,
    name=ctx.attr.name,
    args="%s%s" % (nu.env("RUNFILES"), entry_point_path),
    passthrough_args=ctx.attr.passthrough_args,
  )

  runfiles = _nu_runfiles(ctx)
  default_runfiles = runfiles.merge_all([
    nu.nu_binary[DefaultInfo].default_runfiles,
  ])

  defaultinfo = DefaultInfo(
    executable = output_file,
    runfiles = default_runfiles,
  )
  return [
    defaultinfo,
    NuModuleInfo(
      defaultinfo = DefaultInfo(runfiles=runfiles),
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
    "passthrough_args": attr.bool(
      default = False,
    ),
  },
  executable = True,
  toolchains = [
    "//toolchain:toolchain_type",
  ],
  provides = [DefaultInfo, NuModuleInfo],
)
