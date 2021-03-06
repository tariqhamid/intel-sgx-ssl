#
# Copyright (C) 2011-2017 Intel Corporation. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
#
#   * Redistributions of source code must retain the above copyright
#     notice, this list of conditions and the following disclaimer.
#   * Redistributions in binary form must reproduce the above copyright
#     notice, this list of conditions and the following disclaimer in
#     the documentation and/or other materials provided with the
#     distribution.
#   * Neither the name of Intel Corporation nor the names of its
#     contributors may be used to endorse or promote products derived
#     from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
# A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
# OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
# LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
# THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
#


######## SGX SDK Settings ########
SGX_MODE ?= HW
SGX_ARCH ?= x64

ifeq ($(shell getconf LONG_BIT), 32)
	SGX_ARCH := x86
else ifeq ($(findstring -m32, $(CXXFLAGS)), -m32)
	SGX_ARCH := x86
endif

ifeq ($(SGX_ARCH), x86)
	$(error x86 build is not supported, only x64!!)
else
	SGX_COMMON_CFLAGS := -m64 -Wall
	SGX_EDGER8R := $(SGX_SDK)/bin/x64/sgx_edger8r
endif

ifeq ($(SGX_DEBUG), 1)
ifeq ($(SGX_PRERELEASE), 1)
$(error Cannot set SGX_DEBUG and SGX_PRERELEASE at the same time!!)
endif
endif

ifeq ($(SGX_DEBUG), 1)
        SGX_COMMON_CFLAGS += -O0 -g
else
        SGX_COMMON_CFLAGS += -O2 -D_FORTIFY_SOURCE=2
endif

SgxSSL_Package_Include := ../../package/include
SGX_EDL_FILE := $(SgxSSL_Package_Include)/sgx_tsgxssl.edl

######## App Settings ########

Sgx_ussl_Include_Paths := -I. -I$(SGX_SDK)/include

Sgx_ussl_C_Flags := $(SGX_COMMON_CFLAGS) -fpie -fpic -fstack-protector -Wformat -Wformat-security -Wno-attributes $(Sgx_ussl_Include_Paths)
Sgx_ussl_Cpp_Flags := $(Sgx_ussl_C_Flags) -std=c++11

Sgx_ussl_Cpp_Files := $(wildcard *.cpp)
Sgx_ussl_C_Files := $(wildcard *.c)

Sgx_ussl_Cpp_Objects := $(Sgx_ussl_Cpp_Files:.cpp=.o)
Sgx_ussl_C_Objects := $(Sgx_ussl_C_Files:.c=.o)


.PHONY: all run

all: libsgx_usgxssl.a 

######## App Objects ########

# Lines below are NOT needed because currently the EDL file doesn't contain ECALL function.
#$(UNTRUSTED_DIR)/sgx_tsgxssl_u.c: $(SGX_EDGER8R) $(SGX_EDL_FILE)
#	@mkdir -p $(UNTRUSTED_DIR) && cd $(UNTRUSTED_DIR) && $(SGX_EDGER8R) --header-only --untrusted $(SGX_EDL_FILE) --search-path $(SGX_SDK)/include
#	@echo "GEN  =>  $@"

sgx_tsgxssl_u.o: $(UNTRUSTED_DIR)/sgx_tsgxssl_u.c
	@$(CC) $(Sgx_ussl_C_Flags) -c $< -o $@
	@echo "CC   <=  $<"

%.o: %.cpp
	@$(CC) $(Sgx_ussl_Cpp_Flags) -c $< -o $@
	@echo "CC  <=  $<"

%.o: %.c
	@$(CC) $(Sgx_ussl_C_Flags) -c $< -o $@
	@echo "CC  <=  $<"

libsgx_usgxssl.a: $(Sgx_ussl_Cpp_Objects) $(Sgx_ussl_C_Objects)
	ar rcs libsgx_usgxssl.a $(Sgx_ussl_Cpp_Objects) $(Sgx_ussl_C_Objects)  
	@echo "LINK =>  $@"

.PHONY: clean

clean:
	@rm -f  libsgx_usgxssl.* sgx_tsgxssl_u.* $(Sgx_ussl_Cpp_Objects) $(Sgx_ussl_C_Objects)
	
