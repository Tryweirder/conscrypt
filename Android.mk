# -*- mode: makefile -*-
# Copyright (C) 2013 The Android Open Source Project
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
# Definitions for building the Conscrypt Java library, native code,
# and associated tests.
#

#
# Common definitions for host and target.
#

# Conscrypt is divided into modules.
#
# The structure is:
#
#   src/
#       main/               # To be shipped on every device.
#            java/          # Java source for library code.
#            native/        # C++ source for library code.
#            resources/     # Support files.
#       test/               # Built only on demand, for testing.
#            java/          # Java source for tests.
#            native/        # C++ source for tests (rare).
#            resources/     # Support files.
#
# All subdirectories are optional (hence the "2> /dev/null"s below).

LOCAL_PATH := $(call my-dir)

local_javac_flags=-encoding UTF-8
#local_javac_flags+=-Xlint:all -Xlint:-serial,-deprecation,-unchecked
local_javac_flags+=-Xmaxwarns 9999999

core_cflags := -Wall -Wextra -Werror
core_cppflags := -std=gnu++11

#
# Build for the target (device).
#

# Java library with no JarJar rules (used for tests and inheritance)
LOCAL_SRC_FILES := $(call all-java-files-under,src/main/java)
LOCAL_JAVA_LIBRARIES := core
LOCAL_NO_STANDARD_LIBRARIES := true
LOCAL_JAVACFLAGS := $(local_javac_flags)
LOCAL_MODULE_TAGS := optional
LOCAL_MODULE := conscrypt-nojarjar
LOCAL_ADDITIONAL_DEPENDENCIES := $(LOCAL_PATH)/Android.mk
include $(BUILD_STATIC_JAVA_LIBRARY)

# Platform Conscrypt library
include $(CLEAR_VARS)
LOCAL_JAVA_LIBRARIES := core
LOCAL_NO_STANDARD_LIBRARIES := true
LOCAL_JARJAR_RULES := $(LOCAL_PATH)/jarjar-rules.txt
LOCAL_MODULE_TAGS := optional
LOCAL_MODULE := conscrypt
LOCAL_REQUIRED_MODULES := libjavacrypto
LOCAL_STATIC_JAVA_LIBRARIES := conscrypt-nojarjar
LOCAL_ADDITIONAL_DEPENDENCIES := $(LOCAL_PATH)/Android.mk
include $(BUILD_JAVA_LIBRARY)

ifeq ($(LIBCORE_SKIP_TESTS),)
# Make the conscrypt-tests library.
include $(CLEAR_VARS)
LOCAL_SRC_FILES := $(call all-java-files-under,src/test/java)
LOCAL_NO_STANDARD_LIBRARIES := true
LOCAL_JAVA_LIBRARIES := bouncycastle core core-junit
LOCAL_STATIC_JAVA_LIBRARIES := core-tests-support conscrypt-nojarjar
LOCAL_JAVACFLAGS := $(local_javac_flags)
LOCAL_MODULE_TAGS := optional
LOCAL_MODULE := conscrypt-tests
LOCAL_REQUIRED_MODULES := libjavacrypto
LOCAL_JARJAR_RULES := $(LOCAL_PATH)/jarjar-rules.txt
LOCAL_ADDITIONAL_DEPENDENCIES := $(LOCAL_PATH)/Android.mk
include $(BUILD_STATIC_JAVA_LIBRARY)
endif

# Platform conscrypt crypto JNI library
include $(CLEAR_VARS)
LOCAL_CFLAGS += $(core_cflags)
LOCAL_CFLAGS += -DJNI_JARJAR_PREFIX="com/android/"
LOCAL_CPPFLAGS += $(core_cppflags)
LOCAL_SRC_FILES := \
        src/main/native/org_conscrypt_NativeCrypto.cpp
LOCAL_C_INCLUDES += \
        external/openssl/include \
        libcore/include \
        libcore/luni/src/main/native
LOCAL_SHARED_LIBRARIES := libcrypto libjavacore liblog libnativehelper libssl libz
LOCAL_MODULE_TAGS := optional
LOCAL_MODULE := libjavacrypto
LOCAL_ADDITIONAL_DEPENDENCIES := $(LOCAL_PATH)/Android.mk
include $(BUILD_SHARED_LIBRARY)

# Unbundled Conscrypt jar
include $(CLEAR_VARS)
exclude_src_files := \
	src/main/java/org/conscrypt/CertPinManager.java \
	src/main/java/org/conscrypt/FileClientSessionCache.java \
	src/main/java/org/conscrypt/JSSEProvider.java \
	src/main/java/org/conscrypt/PinFailureLogger.java \
	src/main/java/org/conscrypt/PinListEntry.java \
	src/main/java/org/conscrypt/Platform.java \
	src/main/java/org/conscrypt/TrustedCertificateIndex.java \
	src/main/java/org/conscrypt/TrustedCertificateKeyStoreSpi.java \
	src/main/java/org/conscrypt/TrustedCertificateStore.java \
	src/main/java/org/conscrypt/TrustManagerFactoryImpl.java \
	src/main/java/org/conscrypt/TrustManagerImpl.java
unbundled_src_files := $(call all-java-files-under,src/main/java)
unbundled_src_files += $(call all-java-files-under,src/compat/java)
unbundled_src_files := $(filter-out $(exclude_src_files), $(unbundled_src_files))
LOCAL_SRC_FILES := $(unbundled_src_files)
LOCAL_SDK_VERSION := 9
LOCAL_JAVACFLAGS := $(local_javac_flags)
LOCAL_MODULE_TAGS := optional
LOCAL_MODULE := conscrypt-unbundled
LOCAL_ADDITIONAL_DEPENDENCIES := $(LOCAL_PATH)/Android.mk
include $(BUILD_STATIC_JAVA_LIBRARY)

# Unbundled Conscrypt crypto JNI library
include $(CLEAR_VARS)
LOCAL_CFLAGS += $(core_cflags)
LOCAL_CPPFLAGS += $(core_cppflags)
LOCAL_SRC_FILES := \
        src/main/native/org_conscrypt_NativeCrypto.cpp \
	src/compat/native/JNIHelp.cpp
LOCAL_C_INCLUDES += \
        external/openssl/include \
	external/conscrypt/src/compat/native
LOCAL_SHARED_LIBRARIES := liblog libz libdl
LOCAL_STATIC_LIBRARIES := libssl_static libcrypto_static
LOCAL_MODULE_TAGS := optional
LOCAL_MODULE := libconscrypt_jni
LOCAL_ADDITIONAL_DEPENDENCIES := $(LOCAL_PATH)/Android.mk
LOCAL_SDK_VERSION := 9
include $(BUILD_SHARED_LIBRARY)

#
# Build for the host.
#

ifeq ($(WITH_HOST_DALVIK),true)
    # Make the conscrypt-hostdex-nojarjar (for tests and inheritance)
    include $(CLEAR_VARS)
    LOCAL_SRC_FILES := $(call all-java-files-under,src/main/java)
    LOCAL_JAVACFLAGS := $(local_javac_flags)
    LOCAL_BUILD_HOST_DEX := true
    LOCAL_MODULE_TAGS := optional
    LOCAL_MODULE := conscrypt-hostdex-nojarjar
    LOCAL_ADDITIONAL_DEPENDENCIES := $(LOCAL_PATH)/Android.mk
    include $(BUILD_HOST_DALVIK_STATIC_JAVA_LIBRARY)

    # Make the conscrypt-hostdex library
    include $(CLEAR_VARS)
    LOCAL_JARJAR_RULES := $(LOCAL_PATH)/jarjar-rules.txt
    LOCAL_MODULE_TAGS := optional
    LOCAL_MODULE := conscrypt-hostdex
    LOCAL_REQUIRED_MODULES := libjavacrypto
    LOCAL_ADDITIONAL_DEPENDENCIES := $(LOCAL_PATH)/Android.mk
    LOCAL_STATIC_JAVA_LIBRARIES := conscrypt-hostdex-nojarjar
    include $(BUILD_HOST_DALVIK_JAVA_LIBRARY)

    # Make the conscrypt-tests library.
    ifeq ($(LIBCORE_SKIP_TESTS),)
    include $(CLEAR_VARS)
    LOCAL_SRC_FILES := $(call all-java-files-under,src/test/java)
    LOCAL_JAVA_LIBRARIES := bouncycastle-hostdex core-junit-hostdex core-tests-support-hostdex conscrypt-hostdex-nojarjar
    LOCAL_JAVACFLAGS := $(local_javac_flags)
    LOCAL_MODULE_TAGS := optional
    LOCAL_MODULE := conscrypt-tests-hostdex
    LOCAL_REQUIRED_MODULES := libjavacrypto
    LOCAL_ADDITIONAL_DEPENDENCIES := $(LOCAL_PATH)/Android.mk
    include $(BUILD_HOST_DALVIK_JAVA_LIBRARY)
    endif

    # Conscrypt native library for host
    include $(CLEAR_VARS)
    LOCAL_SRC_FILES += \
            src/main/native/org_conscrypt_NativeCrypto.cpp
    LOCAL_C_INCLUDES += \
            external/openssl/include \
            libcore/include \
            libcore/luni/src/main/native
    LOCAL_CPPFLAGS += $(core_cppflags)
    LOCAL_LDLIBS += -lpthread
    LOCAL_MODULE_TAGS := optional
    LOCAL_MODULE := libjavacrypto
    LOCAL_CFLAGS += -DJNI_JARJAR_PREFIX="com/android/"
    LOCAL_ADDITIONAL_DEPENDENCIES := $(LOCAL_PATH)/Android.mk
    LOCAL_SHARED_LIBRARIES := libcrypto-host libjavacore liblog libnativehelper libssl-host
    include $(BUILD_HOST_SHARED_LIBRARY)

    # Conscrypt native library for nojarjar'd version
    include $(CLEAR_VARS)
    LOCAL_SRC_FILES += \
            src/main/native/org_conscrypt_NativeCrypto.cpp
    LOCAL_C_INCLUDES += \
            external/openssl/include \
            libcore/include \
            libcore/luni/src/main/native
    LOCAL_CPPFLAGS += $(core_cppflags) -DCONSCRYPT_NOT_UNBUNDLED
    LOCAL_LDLIBS += -lpthread
    LOCAL_MODULE_TAGS := optional
    LOCAL_MODULE := libconscrypt_jni
    LOCAL_ADDITIONAL_DEPENDENCIES := $(LOCAL_PATH)/Android.mk
    LOCAL_SHARED_LIBRARIES := libcrypto-host libjavacore liblog libnativehelper libssl-host
    include $(BUILD_HOST_SHARED_LIBRARY)
endif
