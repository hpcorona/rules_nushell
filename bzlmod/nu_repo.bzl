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

"""Downloads and generates the build file for the nushell repository."""

load("@bazel_skylib//lib:paths.bzl", "paths")

def _download_and_resolve_path(ctx):
  """Downloads and extracts the directory, and then it gets the first directory.
  This helps avoid having to decipher the stripPrefix value.
  """
  output_path = ctx.path("nu")
  ctx.download_and_extract(
    url = ctx.attr.url,
    output = "%s" % output_path,
    sha256 = ctx.attr.sha256,
  )
  extracted = output_path.readdir()
  if len(extracted) == 1:
    return extracted[0]
  return output_path

def _build_file(ctx, output_path, build_template):
  relative_binary = paths.relativize("%s" % output_path, "%s" % ctx.path(''))
  ctx.template(
    "%s" % ctx.path("BUILD.bazel"),
    "%s" % build_template,
    substitutions = {
      "{relative}": relative_binary,
      "{binary}": ctx.attr.binary,
    },
    executable = False,
  )

def _nu_repo_impl(ctx):
  build_template = ctx.path(ctx.attr._build_template)
  output_path = _download_and_resolve_path(ctx)
  _build_file(ctx, output_path, build_template)

nu_repo = repository_rule(
  implementation = _nu_repo_impl,
  attrs = {
    "binary": attr.string(
      mandatory = True,
    ),
    "url": attr.string(
      mandatory = True,
    ),
    "sha256": attr.string(
      mandatory = True,
    ),
    "_build_template": attr.label(
      default = "//bzlmod:gen.nu_repo.BUILD.bazel",
      allow_single_file = True,
    ),
  },
)
