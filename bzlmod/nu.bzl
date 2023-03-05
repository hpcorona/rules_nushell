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
  fields = ['name', 'arch', 'arch_alias', 'suffix', 'binary', 'sha256'],
)

_VERSION = "0.76.0"

_REPOS = [
  _OsArchInfo(
    name = 'nushell-windows-x86_64',
    arch = 'x86_64',
    arch_alias = ['x86_64', 'amd64'],
    suffix = 'pc-windows-msvc.zip',
    binary = 'nu.exe',
    sha256 = '',
  ),
  _OsArchInfo(
    name = 'nushell-linux-arm64',
    arch = 'aarch64',
    arch_alias = ['aarch64'],
    suffix = 'unknown-linux-gnu.tar.gz',
    binary = 'nu',
    sha256 = '',
  ),
  _OsArchInfo(
    name = 'nushell-linux-x86_64',
    arch = 'x86_64',
    arch_alias = ['x86_64', 'amd64'],
    suffix = 'unknown-linux-gnu.tar.gz',
    binary = 'nu',
    sha256 = '',
  ),
  _OsArchInfo(
    name = 'nushell-macos-arm64',
    arch = 'aarch64',
    arch_alias = ['aarch64'],
    suffix = 'apple-darwin.tar.gz',
    binary = 'nu',
    sha256 = '',
  ),
  _OsArchInfo(
    name = 'nushell-macos-x86_64',
    arch = 'x86_64',
    arch_alias = ['x86_64', 'amd64'],
    suffix = 'apple-darwin.tar.gz',
    binary = 'nu',
    sha256 = '',
  ),
]

def _nu_impl(ctx):
  for repo in _REPOS:
    url = "https://github.com/nushell/nushell/releases/download/%s/nu-%s-%s-%s" % (_VERSION, _VERSION, repo.arch, repo.suffix)
    nu_repo(
      name = repo.name,
      url = url,
      sha256 = repo.sha256,
      binary = repo.binary,
    )

nu = module_extension(
  implementation = _nu_impl,
)
