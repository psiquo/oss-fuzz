#!/bin/bash -eu
# Copyright 2021 Google LLC
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

compile_package () {
    pkg=$1
    pkg_flat=`echo $pkg | sed 's/\//_/g'`
    args=`cat $SRC/ngolo-fuzzing/std/exclude.txt | grep $pkg_flat | awk '{print "-exclude", $2}'`
    ./ngolo-fuzzing $args $pkg fuzz_ng_$pkg_flat
    (
        cd fuzz_ng_$pkg_flat
        $SRC/LPM/external.protobuf/bin/protoc --go_out=./ ngolofuzz.proto
        mkdir cpp
        $SRC/LPM/external.protobuf/bin/protoc --cpp_out=./cpp ngolofuzz.proto
        $CXX -stdlib=libc++ -c -I . -I $SRC/LPM/external.protobuf/include cpp/ngolofuzz.pb.cc
        $CXX $CXXFLAGS -c -Icpp -I $SRC/libprotobuf-mutator/ -I $SRC/LPM/external.protobuf/include $SRC/ngolo-fuzzing/lpm/ngolofuzz.cc
    )
    compile_go_fuzzer ./fuzz_ng_$pkg_flat FuzzNG_unsure fuzz_ngo_$pkg_flat

    ./go114-fuzz-build/go114-fuzz-build -func FuzzNG_valid -o fuzz_ng_$pkg_flat.a ./fuzz_ng_$pkg_flat

    $CXX $CXXFLAGS $LIB_FUZZING_ENGINE fuzz_ng_$pkg_flat/ngolofuzz.pb.o fuzz_ng_$pkg_flat//ngolofuzz.o fuzz_ng_$pkg_flat.a  $SRC/LPM/src/libfuzzer/libprotobuf-mutator-libfuzzer.a $SRC/LPM/src/libprotobuf-mutator.a $SRC/LPM/external.protobuf/lib/libprotobuf.a -o $OUT/fuzz_ng_$pkg_flat
}

go build

(
cd go114-fuzz-build
go build
)

# maybe we should git clone --depth 1 https://github.com/golang/go.git
find /root/.go/src/ -type d | cut -d/ -f5- | while read pkg; do
    if [[ `ls /root/.go/src/$pkg/*.go | wc -l` == '0' ]]; then
        continue
    fi
    if [[ `echo $pkg | grep internal | wc -l` == '1' ]]; then
        continue
    fi
    if [[ `echo $pkg | grep vendor | wc -l` == '1' ]]; then
        continue
    fi
    if [[ `echo $pkg | grep testdata | wc -l` == '1' ]]; then
        continue
    fi
    if compile_package $pkg; then
        echo $pkg >> ok.txt
    else
        echo "Failed for $pkg"
        # hard fail if the package is meant to be supported
        grep ^$pkg$ $SRC/ngolo-fuzzing/std/supported.txt && exit 1
        echo $pkg >> ko.txt
    fi

done

echo "Failed packages:"
cat ko.txt

echo "Succesful packages:"
cat ok.txt
