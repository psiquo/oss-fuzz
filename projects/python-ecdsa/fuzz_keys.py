#!/usr/bin/python3
# Copyright 2023 Google LLC
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
import sys
import atheris
import hashlib
import binascii

import ecdsa
from ecdsa.keys import VerifyingKey


def target1(fdp):
  try:
    VerifyingKey.from_der(fdp.ConsumeBytes(sys.maxsize))
  except ecdsa.der.UnexpectedDER:
    pass


def target2(fdp):
  try:
    VerifyingKey.from_pem(fdp.ConsumeBytes(sys.maxsize), hashlib.sha256)
  except ecdsa.der.UnexpectedDER:
    pass
  except binascii.Error:
    pass


def target3(fdp):
  try:
    VerifyingKey.from_public_key_recovery_with_digest(
        fdp.ConsumeBytes(sys.maxsize), fdp.ConsumeBytes(sys.maxsize),
        ecdsa.curves.Ed25519)
  except ecdsa.der.UnexpectedDER:
    pass
  except ValueError:
    pass


def target4(fdp):
  try:
    VerifyingKey.from_string(fdp.ConsumeUnicodeNoSurrogates(sys.maxsize),
                             ecdsa.curves.Ed25519)
  except ecdsa.keys.MalformedPointError:
    pass
  except ecdsa.der.UnexpectedDER:
    pass
  except ValueError:
    pass


def target5(fdp):
  vk_str = fdp.ConsumeUnicodeNoSurrogates(sys.maxsize)
  sig = fdp.ConsumeBytes(sys.maxsize)
  data = fdp.ConsumeBytes(sys.maxsize)
  try:
    vk = VerifyingKey.from_pem(vk_str)
    vk.verify(sig, data)
  except ecdsa.keys.MalformedPointError:
    pass
  except ecdsa.der.UnexpectedDER:
    pass
  except ValueError:
    pass


def TestOneInput(data):
  fdp = atheris.FuzzedDataProvider(data)
  targets = [
      target1,
      target2,
      target3,
      target4,
      target5,
  ]

  target = fdp.PickValueInList(targets)
  target(fdp)


def main():
  atheris.instrument_all()
  atheris.Setup(sys.argv, TestOneInput)
  atheris.Fuzz()


if __name__ == "__main__":
  main()
