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
"""Tests for filestore_utils."""
import unittest
from unittest import mock

import parameterized

import filestore
from filestore import github_actions
import filestore_utils
import test_helpers


class GetFilestoreTest(unittest.TestCase):
  """Tests for get_filestore."""

  @parameterized.parameterized.expand([
      ({
          'build_integration_path': '/',
          'is_github': True,
      }, github_actions.GithubActionsFilestore),
  ])
  def test_get_filestore(self, config_kwargs, filestore_cls):
    """Tests that get_filestore returns the right filestore given a certain
    platform."""
    run_config = test_helpers.create_run_config(**config_kwargs)
    filestore_impl = filestore_utils.get_filestore(run_config)
    self.assertIsInstance(filestore_impl, filestore_cls)

  def test_get_filestore_unsupported_platform(self):
    """Tests that get_filestore exceptions given a platform it doesn't
    support."""
    with mock.patch('config_utils.BaseConfig.platform', return_value='other'):
      run_config = test_helpers.create_run_config()
      with self.assertRaises(filestore.FilestoreError):
        filestore_utils.get_filestore(run_config)
