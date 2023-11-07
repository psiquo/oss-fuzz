#!/bin/bash -eu
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
#
################################################################################

# fuzz-introspector isn't compatible with meson. Let's bail out explicitly here.
# https://github.com/systemd/systemd/commit/ebd4541efe800190e5f158179f8201c654bb4c31
if [[ "$SANITIZER" == introspector ]]; then
    exit 1
fi

apt-get update -y

if [[ "$ARCHITECTURE" == i386 ]]; then
    apt-get install -y pkg-config:i386
else
    apt-get install -y pkg-config
fi

if [[ "$SANITIZER" == undefined ]]; then
    additional_ubsan_checks=alignment
    UBSAN_FLAGS="-fsanitize=$additional_ubsan_checks -fno-sanitize-recover=$additional_ubsan_checks"
    CFLAGS+=" $UBSAN_FLAGS"
    CXXFLAGS+=" $UBSAN_FLAGS"
fi

pip3 install meson ninja

if ! meson -Db_lundef=false -Dlauncher=false build; then
    cat build/meson-logs/meson-log.txt
    exit 1
fi

ninja -C ./build -v
$CC $CFLAGS -c -o fuzz-message.o -Isrc -Isubprojects/libcstdaux-1/src -std=c11 -D_GNU_SOURCE "$SRC/fuzz-message.c"
$CXX $CXXFLAGS -o "$OUT/fuzz-message" \
    fuzz-message.o \
    build/src/libbus-static.a \
    build/subprojects/libcdvar-1/src/libcdvar-1.a \
    build/subprojects/libcutf8-1/src/libcutf8-1.a \
    $LIB_FUZZING_ENGINE
