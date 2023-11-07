/* Copyright 2022 Google LLC
Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at
      http://www.apache.org/licenses/LICENSE-2.0
Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/
#include <stdlib.h>
#include <stdio.h>
#include <string.h>

#include "ns_turn_utils.h"
#include "apputils.h"
#include "stun_buffer.h"

#define kMinInputLength 5
#define kMaxInputLength 10240

extern int LLVMFuzzerTestOneInput(const uint8_t *Data, size_t Size) {//stunclient.c

    if (Size < kMinInputLength || Size > kMaxInputLength){
        return 1;
    }

    stun_buffer buf;

    buf.len = Size;
    memcpy(buf.buf,Data,buf.len);

    if(stun_is_command_message(&buf)){
        if(stun_is_response(&buf)){
            if(stun_is_success_response(&buf)){
                if(stun_is_binding_response(&buf)){
                    return 0;
                }
            }
        }
    }

    return 1;
}
