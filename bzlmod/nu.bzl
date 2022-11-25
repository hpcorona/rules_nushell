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

"""Identifies the repository to download for nushell."""

load(":nu_repo.bzl", "nu_repo")

_OsArchInfo = provider(
  fields = ['os', 'arch', 'arch_alias', 'suffix', 'binary', 'sha256'],
)

_VERSION = "0.71.0"

_REPOS = [
  _OsArchInfo(
    os = 'windows',
    arch = 'x86_64',
    arch_alias = ['x86_64', 'amd64'],
    suffix = 'pc-windows-msvc.zip',
    binary = 'nu.exe',
    sha256 = '',
  ),
  _OsArchInfo(
    os = 'linux',
    arch = 'aarch64',
    arch_alias = ['aarch64'],
    suffix = 'unknown-linux-gnu.tar.gz',
    binary = 'nu',
    sha256 = '',
  ),
  _OsArchInfo(
    os = 'linux',
    arch = 'armv7',
    arch_alias = ['armv7'],
    suffix = 'unknown-linux-gnueabihf.tar.gz',
    binary = 'nu',
    sha256 = '',
  ),
  _OsArchInfo(
    os = 'linux',
    arch = 'x86_64',
    arch_alias = ['x86_64', 'amd64'],
    suffix = 'unknown-linux-gnu.tar.gz',
    binary = 'nu',
    sha256 = '',
  ),
  _OsArchInfo(
    os = 'darwin',
    arch = 'aarch64',
    arch_alias = ['aarch64'],
    suffix = 'apple-darwin.tar.gz',
    binary = 'nu',
    sha256 = '',
  ),
  _OsArchInfo(
    os = 'darwin',
    arch = 'x86_64',
    arch_alias = ['x86_64', 'amd64'],
    suffix = 'apple-darwin.tar.gz',
    binary = 'nu',
    sha256 = '',
  ),
]

def _nu_impl(ctx):
  os_name = ctx.os.name
  if os_name.startswith('windows'):
    os_name = 'windows'
  repos = [repo for repo in _REPOS if repo.os == os_name and ctx.os.arch in repo.arch_alias]
  if len(repos) != 1:
    fail("no repos found for %s/%s (ctx.os.name = %s)" % (os_name, ctx.os.arch, ctx.os.name))
  repo = repos[0]
  url = "https://github.com/nushell/nushell/releases/download/%s/nu-%s-%s-%s" % (_VERSION, _VERSION, repo.arch, repo.suffix)
  nu_repo(
    name = "nushell",
    url = url,
    sha256 = repo.sha256,
    binary = repo.binary,
  )

nu = module_extension(
  implementation = _nu_impl,
)
