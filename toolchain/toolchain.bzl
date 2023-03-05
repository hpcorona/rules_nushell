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
  fields = ["nu_binary", "nu_kwargs", "nu_runner", "env", "extension", "sep", "env_pattern", "template", "template_args"],
)

Tool = provider(
  doc = "Information to execute ctx.actions.run(**tool.kwargs).",
  fields = ["executable", "env", "input_manifests", "tools", "kwargs"],
)

def _resolve_tool(tool):
  def _resolve(ctx):
    (tools, tools_manifests) = ctx.resolve_tools(tools=[tool])
    tool_binary = tool[DefaultInfo].files_to_run.executable
    runfiles_path = '%s.runfiles/%s/' % (tool_binary.path, ctx.workspace_name)
    env = {
      'RUNFILES': runfiles_path,
    }
    kwa = {
      'executable': tool_binary,
      'env': env,
      'input_manifests': tools_manifests,
      'tools': tools,
    }

    return Tool(
      executable=tool_binary,
      env=env,
      input_manifests=tools_manifests,
      tools=tools,
      kwargs=kwa,
    )
  return _resolve

def _create_runner(*, tool, extension, sep, template, template_args):
  def _work(ctx, *, name, args='', passthrough_args=False):
    tpl = template if not passthrough_args else template_args
    runner = ctx.actions.declare_file('%s.%s' % (name, extension))
    runfiles_path = '%s.%s.runfiles/%s/' % (name, extension, ctx.workspace_name)
    ctx.actions.expand_template(
        template=tpl,
        output=runner,
        substitutions={
            '{nu_binary}': tool.short_path.replace('/', sep),
            '{args}': args,
            '{runfiles_path}': runfiles_path,
            '{bin_dir}': ctx.bin_dir.path,
        },
        is_executable=True,
    )
    return runner
  return _work

def _env(env_pattern):
  def _resolve(name):
    return env_pattern % name
  return _resolve

def _nu_toolchain_impl(ctx):
  return [
    platform_common.ToolchainInfo(
      info = NuInfo(
        nu_binary = ctx.attr.binary,
        nu_kwargs = _resolve_tool(ctx.attr.binary),
        nu_runner = _create_runner(
          tool=ctx.executable.binary,
          extension=ctx.attr.extension,
          sep=ctx.attr.sep,
          template=ctx.file.template,
          template_args=ctx.file.template_args,
        ),
        env = _env(ctx.attr.env_pattern),
        extension = ctx.attr.extension,
        sep = ctx.attr.sep,
        env_pattern = ctx.attr.env_pattern,
        template = ctx.file.template,
        template_args = ctx.file.template_args,
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
    "extension": attr.string(
      default = 'sh',
    ),
    "sep": attr.string(
      default = '/',
    ),
    "env_pattern": attr.string(
      default = '${%s}',
    ),
    "template": attr.label(
      allow_single_file = True,
      default = "//toolchain:gen.runner.default.sh",
    ),
    "template_args": attr.label(
      allow_single_file = True,
      default = "//toolchain:gen.runner.args.default.sh",
    ),
  },
)

def define_platform_and_toolchain(*, os, cpu, **kwargs):
  suffix = "%s-%s" % (os, cpu)
  native.platform(
    name="platform-%s" % suffix,
    constraint_values=[
      "@platforms//os:%s" % os,
      "@platforms//cpu:%s" % cpu,
    ],
  )

  nu_toolchain(
    name = "nu_toolchain-%s" % suffix,
    binary = "@nushell-%s//:nu_binary" % suffix,
    **kwargs
  )

  native.toolchain(
    name = "toolchain-%s" % suffix,
    toolchain = ":nu_toolchain-%s" % suffix,
    toolchain_type = "//toolchain:toolchain_type",
    exec_compatible_with = [
      "@platforms//os:%s" % os,
      "@platforms//cpu:%s" % cpu,
    ],
    target_compatible_with = [
      "@platforms//os:%s" % os,
      "@platforms//cpu:%s" % cpu,
    ],
  )
