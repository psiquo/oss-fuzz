#!/bin/bash -eu
# Copyright 2016 Google Inc.
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

# afl++ CMPLOG test:
test "$FUZZING_ENGINE" = "afl" && {
  export AFL_LLVM_CMPLOG=1
  touch $OUT/afl_cmplog.txt
}

# Build SwiftShader
pushd third_party/externals/swiftshader/
export SWIFTSHADER_INCLUDE_PATH=$PWD/include
# SwiftShader already has a build/ directory, use something else
rm -rf build_swiftshader
mkdir build_swiftshader

cd build_swiftshader
if [ $SANITIZER == "address" ]; then
  CMAKE_SANITIZER="SWIFTSHADER_ASAN"
elif [ $SANITIZER == "memory" ]; then
  CMAKE_SANITIZER="SWIFTSHADER_MSAN"
  # oss-fuzz will patch the rpath for this after compilation and linking,
  # so we only need to set this to appease the Swiftshader build rules check.
  export SWIFTSHADER_MSAN_INSTRUMENTED_LIBCXX_PATH="/does/not/matter"
elif [ $SANITIZER == "undefined" ]; then
  # The current SwiftShader build needs -fno-sanitize=vptr, but it cannot be
  # specified here since -fsanitize=undefined will always come after any
  # user specified flags passed to cmake. SwiftShader does not need to be
  # built with the undefined sanitizer in order to fuzz Skia, so don't.
  CMAKE_SANITIZER="SWIFTSHADER_UBSAN_DISABLED"
elif [ $SANITIZER == "coverage" ]; then
  CMAKE_SANITIZER="SWIFTSHADER_EMIT_COVERAGE"
else
  exit 1
fi
CFLAGS= CXXFLAGS="-stdlib=libc++" cmake .. -GNinja -DCMAKE_MAKE_PROGRAM="$SRC/depot_tools/ninja" -D$CMAKE_SANITIZER=1

$SRC/depot_tools/ninja libGLESv2 libEGL
cp libGLESv2.so libEGL.so $OUT
export SWIFTSHADER_LIB_PATH=$OUT

popd
# These are any clang warnings we need to silence.
DISABLE="-Wno-zero-as-null-pointer-constant -Wno-unused-template
         -Wno-cast-qual"
# Disable UBSan vptr since target built with -fno-rtti.
export CFLAGS="$CFLAGS $DISABLE -I$SWIFTSHADER_INCLUDE_PATH -DGR_EGL_TRY_GLES3_THEN_GLES2 -fno-sanitize=vptr"
export CXXFLAGS="$CXXFLAGS $DISABLE -I$SWIFTSHADER_INCLUDE_PATH -DGR_EGL_TRY_GLES3_THEN_GLES2 -fno-sanitize=vptr"
export LDFLAGS="$LIB_FUZZING_ENGINE $CXXFLAGS -L$SWIFTSHADER_LIB_PATH"

# This splits a space separated list into a quoted, comma separated list for gn.
export CFLAGS_ARR=`echo $CFLAGS | sed -e "s/\s/\",\"/g"`
export CXXFLAGS_ARR=`echo $CXXFLAGS | sed -e "s/\s/\",\"/g"`
export LDFLAGS_ARR=`echo $LDFLAGS | sed -e "s/\s/\",\"/g"`

$SRC/skia/bin/fetch-gn

set +u
LIMITED_LINK_POOL="link_pool_depth=1"
if [ "$CIFUZZ" = "true" ]; then
  echo "Not restricting linking because on CIFuzz"
  LIMITED_LINK_POOL=""
fi
set -u

# Even though GPU is "enabled" for all these builds, none really
# uses the gpu except for api_mock_gpu_canvas
$SRC/skia/bin/gn gen out/Fuzz\
    --args='cc="'$CC'"
      cxx="'$CXX'"
      '$LIMITED_LINK_POOL'
      is_debug=false
      extra_cflags_c=["'"$CFLAGS_ARR"'"]
      extra_cflags_cc=["'"$CXXFLAGS_ARR"'"]
      extra_ldflags=["'"$LDFLAGS_ARR"'"]
      skia_build_fuzzers=true
      skia_enable_fontmgr_custom_directory=false
      skia_enable_fontmgr_custom_embedded=false
      skia_enable_fontmgr_custom_empty=true
      skia_enable_gpu=true
      skia_enable_skottie=true
      skia_use_egl=true
      skia_use_fontconfig=false
      skia_use_freetype=true
      skia_use_system_freetype2=false
      skia_use_wuffs=true
      skia_use_libfuzzer_defaults=false'

$SRC/depot_tools/ninja -C out/Fuzz \
  android_codec \
  animated_image_decode \
  api_create_ddl \
  api_draw_functions \
  api_gradients \
  api_image_filter \
  api_mock_gpu_canvas \
  api_null_canvas \
  api_path_measure \
  api_pathop \
  api_polyutils \
  api_raster_n32_canvas \
  api_skparagraph \
  api_svg_canvas \
  image_decode \
  image_decode_incremental \
  image_filter_deserialize \
  jpeg_encoder \
  path_deserialize \
  png_encoder \
  region_deserialize \
  region_set_path \
  skdescriptor_deserialize \
  skjson \
  skottie_json \
  skp \
  skruntimeeffect \
  sksl2glsl \
  sksl2metal \
  sksl2pipeline \
  sksl2spirv \
  svg_dom \
  textblob_deserialize \
  webp_encoder

rm -rf $OUT/data
mkdir $OUT/data

cp out/Fuzz/region_deserialize $OUT/region_deserialize

cp out/Fuzz/region_set_path $OUT/region_set_path
cp ../skia_data/region_set_path_seed_corpus.zip $OUT/region_set_path_seed_corpus.zip

cp out/Fuzz/textblob_deserialize $OUT/textblob_deserialize
cp ../skia_data/textblob_deserialize_seed_corpus.zip $OUT/textblob_deserialize_seed_corpus.zip

cp out/Fuzz/path_deserialize $OUT/path_deserialize
cp ../skia_data/path_deserialize_seed_corpus.zip $OUT/path_deserialize_seed_corpus.zip

cp out/Fuzz/image_decode $OUT/image_decode
cp ../skia_data/image_decode_seed_corpus.zip $OUT/image_decode_seed_corpus.zip

cp out/Fuzz/animated_image_decode $OUT/animated_image_decode
cp ../skia_data/animated_image_decode_seed_corpus.zip $OUT/animated_image_decode_seed_corpus.zip

cp out/Fuzz/image_filter_deserialize $OUT/image_filter_deserialize
cp ../skia_data/image_filter_deserialize_seed_corpus.zip $OUT/image_filter_deserialize_seed_corpus.zip

# Only create the width version of image_filter_deserialize if building with
# libfuzzer, since it depends on a libfuzzer specific flag.
if [ "$FUZZING_ENGINE" == "libfuzzer" ]
then
  # Use the same binary as image_filter_deserialize.
  cp out/Fuzz/image_filter_deserialize $OUT/image_filter_deserialize_width
  cp ../skia_data/image_filter_deserialize_width.options $OUT/image_filter_deserialize_width.options
  # Use the same seed corpus as image_filter_deserialize.
  cp ../skia_data/image_filter_deserialize_seed_corpus.zip $OUT/image_filter_deserialize_width_seed_corpus.zip
fi

cp out/Fuzz/api_draw_functions $OUT/api_draw_functions
cp ../skia_data/api_draw_functions_seed_corpus.zip $OUT/api_draw_functions_seed_corpus.zip

cp out/Fuzz/api_gradients $OUT/api_gradients
cp ../skia_data/api_gradients_seed_corpus.zip $OUT/api_gradients_seed_corpus.zip

cp out/Fuzz/api_path_measure $OUT/api_path_measure
cp ../skia_data/api_path_measure_seed_corpus.zip $OUT/api_path_measure_seed_corpus.zip

cp out/Fuzz/api_pathop $OUT/api_pathop
cp ../skia_data/api_pathop_seed_corpus.zip $OUT/api_pathop_seed_corpus.zip

cp out/Fuzz/png_encoder $OUT/png_encoder
cp ../skia_data/encoder_seed_corpus.zip $OUT/png_encoder_seed_corpus.zip

cp out/Fuzz/jpeg_encoder $OUT/jpeg_encoder
cp ../skia_data/encoder_seed_corpus.zip $OUT/jpeg_encoder_seed_corpus.zip

cp out/Fuzz/webp_encoder $OUT/webp_encoder
cp ../skia_data/encoder_seed_corpus.zip $OUT/webp_encoder_seed_corpus.zip

cp out/Fuzz/skottie_json $OUT/skottie_json
cp ../skia_data/skottie_json_seed_corpus.zip $OUT/skottie_json_seed_corpus.zip

cp out/Fuzz/skjson $OUT/skjson
cp ../skia_data/json.dict $OUT/skjson.dict
cp ../skia_data/skjson_seed_corpus.zip $OUT/skjson_seed_corpus.zip

cp out/Fuzz/api_mock_gpu_canvas $OUT/api_mock_gpu_canvas
cp ../skia_data/canvas_seed_corpus.zip $OUT/api_mock_gpu_canvas_seed_corpus.zip

cp out/Fuzz/api_raster_n32_canvas $OUT/api_raster_n32_canvas
cp ../skia_data/canvas_seed_corpus.zip $OUT/api_raster_n32_canvas_seed_corpus.zip

cp out/Fuzz/api_image_filter $OUT/api_image_filter
cp ../skia_data/api_image_filter_seed_corpus.zip $OUT/api_image_filter_seed_corpus.zip

cp out/Fuzz/api_null_canvas $OUT/api_null_canvas
cp ../skia_data/canvas_seed_corpus.zip $OUT/api_null_canvas_seed_corpus.zip

cp out/Fuzz/api_polyutils $OUT/api_polyutils
cp ../skia_data/api_polyutils_seed_corpus.zip $OUT/api_polyutils_seed_corpus.zip

# These 2 can use the same corpus as the (non animated) image_decode.
cp out/Fuzz/android_codec $OUT/android_codec
cp ../skia_data/image_decode_seed_corpus.zip $OUT/android_codec_seed_corpus.zip.

cp out/Fuzz/image_decode_incremental $OUT/image_decode_incremental
cp ../skia_data/image_decode_seed_corpus.zip $OUT/image_decode_incremental_seed_corpus.zip

cp out/Fuzz/sksl2glsl $OUT/sksl2glsl
cp ../skia_data/sksl_seed_corpus.zip $OUT/sksl2glsl_seed_corpus.zip

cp out/Fuzz/sksl2spirv $OUT/sksl2spirv
cp ../skia_data/sksl_seed_corpus.zip $OUT/sksl2spirv_seed_corpus.zip

cp out/Fuzz/sksl2metal $OUT/sksl2metal
cp ../skia_data/sksl_seed_corpus.zip $OUT/sksl2metal_seed_corpus.zip

cp out/Fuzz/sksl2pipeline $OUT/sksl2pipeline
cp ../skia_data/sksl_seed_corpus.zip $OUT/sksl2pipeline_seed_corpus.zip

cp out/Fuzz/skdescriptor_deserialize $OUT/skdescriptor_deserialize

cp out/Fuzz/svg_dom $OUT/svg_dom
cp ../skia_data/svg_dom_seed_corpus.zip $OUT/svg_dom_seed_corpus.zip

cp out/Fuzz/api_svg_canvas $OUT/api_svg_canvas
cp ../skia_data/canvas_seed_corpus.zip $OUT/api_svg_canvas_seed_corpus.zip

cp out/Fuzz/skruntimeeffect $OUT/skruntimeeffect
cp ../skia_data/sksl_with_256_padding_seed_corpus.zip $OUT/skruntimeeffect_seed_corpus.zip

cp out/Fuzz/api_create_ddl $OUT/api_create_ddl

cp out/Fuzz/skp $OUT/skp
cp ../skia_data/skp_seed_corpus.zip $OUT/skp_seed_corpus.zip

cp out/Fuzz/api_skparagraph $OUT/api_skparagraph
