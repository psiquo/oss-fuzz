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

zip "${OUT}/FuzzLoadCertificates_seed_corpus.zip" corpus/pem/*
zip "${OUT}/FuzzUnmarshalCertificatesFromPEM_seed_corpus.zip" corpus/pem/*
zip "${OUT}/FuzzUnmarshalPEMToPublicKey_seed_corpus.zip" corpus/pem/*
zip "${OUT}/FuzzED25529SignerVerfier_seed_corpus.zip" corpus/ed25519/*

compile_go_fuzzer github.com/sigstore/sigstore/test/fuzz FuzzGetPassword FuzzGetPassword
compile_go_fuzzer github.com/sigstore/sigstore/test/fuzz/pem FuzzLoadCertificates FuzzLoadCertificates
compile_go_fuzzer github.com/sigstore/sigstore/test/fuzz/pem FuzzUnmarshalCertificatesFromPEM FuzzUnmarshalCertificatesFromPEM
compile_go_fuzzer github.com/sigstore/sigstore/test/fuzz/pem FuzzUnmarshalPEMToPublicKey FuzzUnmarshalPEMToPublicKey
compile_go_fuzzer github.com/sigstore/sigstore/test/fuzz/signature FuzzECDSASigner FuzzECDSASigner
compile_go_fuzzer github.com/sigstore/sigstore/test/fuzz/signature FuzzComputeDigest FuzzComputeDigest
compile_go_fuzzer github.com/sigstore/sigstore/test/fuzz/signature FuzzComputeVerifying FuzzComputeVerifying
compile_go_fuzzer github.com/sigstore/sigstore/test/fuzz/signature FuzzED25529SignerVerfier FuzzED25529SignerVerfier
compile_go_fuzzer github.com/sigstore/sigstore/test/fuzz/signature FuzzRSAPKCS1v15SignerVerfier FuzzRSAPKCS1v15SignerVerfier
compile_go_fuzzer github.com/sigstore/sigstore/test/fuzz/signature FuzzRSAPSSSignerVerfier FuzzRSAPSSSignerVerfier

