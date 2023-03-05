#!/bin/bash -eu
#
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

# Runs the binary using bash.

RUNFILES=${RUNFILES:-}
BUILD_WORKING_DIRECTORY=${BUILD_WORKING_DIRECTORY:-}
if [[ -z "${RUNFILES}" ]]; then
  if [[ -z "${BUILD_WORKING_DIRECTORY}" ]]; then
    SOURCE=${BASH_SOURCE[0]}
    while [ -L "$SOURCE" ]; do
      DIR=$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )
      SOURCE=$(readlink "$SOURCE")
      [[ $SOURCE != /* ]] && SOURCE=$DIR/$SOURCE
    done
    DIR=$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )
    RUNFILES=${DIR}/{runfiles_path}
  else
    RUNFILES=${BUILD_WORKING_DIRECTORY}/{bin_dir}/{runfiles_path}
  fi
fi
NUARGS="$@" exec ${RUNFILES}{nu_binary} {args}
