#!/bin/bash

# Function to display usage information
usage() {
    echo "Usage: $0 [-h] [-p <PROJECT_NAME>] [-i] [-f] [-d] [path]" 1>&2;
    echo "Options:" 1>&2;
    echo "    -h  Display this help message." 1>&2;
    echo "    -p  Path name." 1>&2;
    echo "    -i  Install dependencies." 1>&2;
    echo "    -f  Force this script to proceed even with errors." 1>&2;
    echo "    -d  Enable this script debugging." 1>&2;
    echo "    path  Path to the project directory." 1>&2;
    exit 1;
}

install_deps() {
    # Install CMake
    if ! command -v cmake &> /dev/null; then
        echo "Installing CMake..."
        sudo apt-get install -y cmake
    fi

    # Install Git
    if ! command -v git &> /dev/null; then
        echo "Installing Git..."
        sudo apt-get install -y git
    fi

    # Install Ninja
    if ! command -v ninja &> /dev/null; then
        echo "Installing Ninja..."
        sudo apt-get install -y ninja-build
    fi

    sudo apt-get install -y libgtest-dev
}

IGNORE_SCRIPT_ERRORS=0
SCRIPT_DEBUG=0

# Default values
PROJECT_NAME=""
DEFAULT_CXX_STD="20"
DEFAULT_C_STD="11"
PROJECT_DIR=""

ENABLE_C_EXTENSIONS="ON"
ENABLE_CXX_EXTENSIONS="ON"

GENERATOR="Ninja"

# If Ninja is not installed, use Make
if ! command -v ninja &> /dev/null; then
    GENERATOR="Unix Makefiles"
fi

# Parse command-line options
while getopts ":hp:c:ifd" o; do
    case "${o}" in
        h)
            usage
            ;;
        p)
            PROJECT_DIR=${OPTARG}
            ;;
        i)
            install_deps
            exit 0
            ;;
        f)
            IGNORE_SCRIPT_ERRORS=1
            ;;
        d)
            SCRIPT_DEBUG=1
            ;;
        \?)
            echo "Invalid option: $OPTARG" >&2
            usage
            ;;
        :)
            echo "Option -$OPTARG requires an argument." >&2
            usage
            ;;
    esac
done
shift $((OPTIND-1))

# Enable debugging
if [[ ${SCRIPT_DEBUG} -eq 1 ]]; then
    set -x
fi

if [[ ${IGNORE_SCRIPT_ERRORS} -eq 0 ]]; then
    set -e
fi

# If the path is provided as an argument
if [[ -n "${1}" ]]; then
    PROJECT_NAME="${1}"
fi

# Check if CMake is installed
if ! command -v cmake &> /dev/null; then
    echo "CMake is required to initialize a C++ project."
    exit 1
fi

# Check if Git is installed
if ! command -v git &> /dev/null; then
    echo "Git is required to initialize a C++ project."
    exit 1
fi

if [[ -z "${PROJECT_DIR}" ]]; then
    PROJECT_DIR="${PROJECT_NAME}"
fi

if [[ -z "${PROJECT_NAME}" ]]; then
    echo "Project name is required."
    usage
fi

if [[ "${PROJECT_NAME}" == *" "* ]]; then
    echo "Project name cannot contain spaces."
    exit 1
fi

if [ "$(ls -A ${PROJECT_DIR})" ]; then
    echo "Directory ${PROJECT_DIR} is not empty."
    exit 1
fi

# Create project directory
mkdir -p "${PROJECT_DIR}/include" "${PROJECT_DIR}/src" "${PROJECT_DIR}/build" "${PROJECT_DIR}/tests"

# Initialize Git
cd "${PROJECT_DIR}" || exit
git init

# Create .gitignore
test -f .gitignore || cat <<EOF >.gitignore
.vscode
.cache
.env
bin

# Prerequisites
*.d

# Compiled Object files
*.slo
*.lo
*.o
*.obj

# Precompiled Headers
*.gch
*.pch

# Compiled Dynamic libraries
*.so
*.dylib
*.dll

# Compiled Static libraries
*.lai
*.la
*.a
*.lib

# Executables
*.exe
*.out
*.app

### VisualStudioCode ###
.vscode/*
.vscode/
!.vscode/settings.json
!.vscode/tasks.json
!.vscode/launch.json
!.vscode/extensions.json

build

EOF

# Create CMakeLists.txt
test -f CMakeLists.txt || cat <<EOF >CMakeLists.txt
cmake_minimum_required(VERSION 3.12)
project(${PROJECT_NAME} C CXX)

set(CMAKE_CXX_STANDARD ${DEFAULT_CXX_STD})
set(CMAKE_C_STANDARD ${DEFAULT_C_STD})
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
set(CMAKE_CXX_EXTENSIONS ${ENABLE_CXX_EXTENSIONS})
set(CMAKE_C_EXTENSIONS ${ENABLE_C_EXTENSIONS})

option(ENABLE_TESTS "Enable tests" ON)
option(ENABLE_SANITIZERS "Enable sanitizers" ON)

if (\${CMAKE_CXX_COMPILER_ID} STREQUAL "GNU")
    message(STATUS "Setting G++ flags")
    add_compile_options(-Wall -Werror -Wextra -Wformat-security -Wconversion -Wsign-conversion  -Wno-gnu -Wno-gnu-statement-expression)
elseif(\${CMAKE_CXX_COMPILER_ID} STREQUAL "MSVC")
    message(STATUS "Setting MSVC flags")
    add_compile_options(/W4 /WX)
elseif(\${CMAKE_CXX_COMPILER_ID} STREQUAL "Clang")
    message(STATUS "Setting Clang flags")
    add_compile_options(-Werror -Weverything -Wno-c++98-compat -Wno-c++98-compat-pedantic -Wno-padded -Wno-global-constructors -Wno-exit-time-destructors -Wno-weak-vtables -Wno-documentation -Wno-documentation-unknown-command)
endif()

if(ENABLE_TESTS)
    include(CTest)
    enable_testing()
    find_package(GTest)

    if(GTest_FOUND)
        include(GoogleTest)
    endif()
endif()

if(ENABLE_SANITIZERS)
    add_compile_options(-fsanitize=address -fno-omit-frame-pointer -g -fsanitize=leak -fsanitize=undefined -fsanitize=pointer-compare -fsanitize=pointer-subtract -fsanitize=pointer-overflow -fsanitize=bounds -fsanitize=alignment -fsanitize=bool -fsanitize=enum -fsanitize=vla-bound -fsanitize=float-divide-by-zero -fsanitize=float-cast-overflow -fsanitize=nonnull-attribute -fsanitize=returns-nonnull-attribute -fsanitize=shift -fsanitize=unreachable -fsanitize=vptr -fsanitize=return -fsanitize=signed-integer-overflow -fsanitize=unsigned-integer-overflow -fsanitize=implicit-conversion -fsanitize=integer-divide-by-zero -fsanitize=unreachable -fsanitize=return -fsanitize=signed-integer-overflow -fsanitize=unsigned-integer-overflow -fsanitize=implicit-conversion -fsanitize=integer-divide-by-zero -fsanitize=unreachable -fsanitize=return -fsanitize=signed-integer-overflow -fsanitize=unsigned-integer-overflow -fsanitize=implicit-conversion -fsanitize=integer-divide-by-zero -fsanitize=unreachable -fsanitize=return -fsanitize=signed-integer-overflow -fsanitize=unsigned-integer-overflow -fsanitize=implicit-conversion -fsanitize=integer-divide-by-zero -fsanitize=unreachable -fsanitize=return -fsanitize=signed-integer-overflow -fsanitize=unsigned-integer-overflow -fsanitize=implicit-conversion -fsanitize=integer-divide-by-zero -fsanitize=unreachable -fsanitize=return -fsanitize=signed-integer-overflow -fsanitize=unsigned-integer-overflow -fsanitize=implicit-conversion -fsanitize=integer-divide-by-zero -fsanitize=unreachable -fsanitize=return -fsanitize=signed-integer-overflow -fsanitize=unsigned-integer-overflow -fsanitize=implicit-conversion -fsanitize=integer-divide-by-zero -fsanitize=unreachable -fsanitize=return -fsanitize=signed-integer-overflow -fsanitize=unsigned-integer-overflow -fsanitize=implicit-conversion -fsanitize=integer-divide-by-zero -fsanitize=unreachable -fsanitize=return -fsanitize=signed-integer-overflow -fsanitize=unsigned-integer-overflow)
    add_link_options(-fsanitize=address -fno-omit-frame-pointer -g -fsanitize=leak -fsanitize=undefined -fsanitize=pointer-compare -fsanitize=pointer-subtract -fsanitize=pointer-overflow -fsanitize=bounds -fsanitize=alignment -fsanitize=bool -fsanitize=enum -fsanitize=vla-bound -fsanitize=float-divide-by-zero -fsanitize=float-cast-overflow -fsanitize=nonnull-attribute -fsanitize=returns-nonnull-attribute -fsanitize=shift -fsanitize=unreachable -fsanitize=vptr -fsanitize=return -fsanitize=signed-integer-overflow -fsanitize=unsigned-integer-overflow -fsanitize=implicit-conversion -fsanitize=integer-divide-by-zero -fsanitize=unreachable -fsanitize=return -fsanitize=signed-integer-overflow -fsanitize=unsigned-integer-overflow -fsanitize=implicit-conversion -fsanitize=integer-divide-by-zero -fsanitize=unreachable -fsanitize=return -fsanitize=signed-integer-overflow -fsanitize=unsigned-integer-overflow -fsanitize=implicit-conversion -fsanitize=integer-divide-by-zero -fsanitize=unreachable -fsanitize=return -fsanitize=signed-integer-overflow -fsanitize=unsigned-integer-overflow -fsanitize=implicit-conversion -fsanitize=integer-divide-by-zero -fsanitize=unreachable -fsanitize=return -fsanitize=signed-integer-overflow -fsanitize=unsigned-integer-overflow -fsanitize=implicit-conversion -fsanitize=integer-divide-by-zero -fsanitize=unreachable -fsanitize=return -fsanitize=signed-integer-overflow -fsanitize=unsigned-integer-overflow -fsanitize=implicit-conversion -fsanitize=integer-divide-by-zero -fsanitize=unreachable -fsanitize=return -fsanitize=signed-integer-overflow -fsanitize=unsigned-integer-overflow -fsanitize=implicit-conversion -fsanitize=integer-divide-by-zero -fsanitize=unreachable -fsanitize=return -fsanitize=signed-integer-overflow -fsanitize=unsigned-integer-overflow -fsanitize=implicit-conversion -fsanitize=integer-divide-by-zero -fsanitize=unreachable -fsanitize=return -fsanitize=signed-integer-overflow -fsanitize=unsigned-integer-overflow)
endif()

# Add include directory
include_directories(include)

# Function to filter out excluded files
function(filter_out excluded output)
    set(result "")
    foreach(file \${\${output}})
        if(NOT "\${file}" IN_LIST \${excluded})
            list(APPEND result \${file})
        endif()
    endforeach()
    set(\${output} "\${result}" PARENT_SCOPE)
endfunction()

# Add source files
file(GLOB_RECURSE SOURCES "\${CMAKE_CURRENT_SOURCE_DIR}/src/*.cpp")

# Exclude specific files
set(EXCLUDE_FILES "\${CMAKE_CURRENT_SOURCE_DIR}/src/main.cpp")
filter_out(EXCLUDE_FILES SOURCES)

message(STATUS "Sources: \${SOURCES}")

add_library(${PROJECT_NAME}_lib STATIC \${SOURCES})

# Add executable
add_executable(${PROJECT_NAME} "src/main.cpp")
target_link_libraries(${PROJECT_NAME} ${PROJECT_NAME}_lib)

if(ENABLE_TESTS)
    add_subdirectory(tests)
endif()
EOF

test -f tests/CMakeLists.txt || cat <<EOF >tests/CMakeLists.txt
add_executable(${PROJECT_NAME}_tests test.cpp)
target_link_libraries(${PROJECT_NAME}_tests ${PROJECT_NAME}_lib GTest::GTest GTest::Main)
gtest_discover_tests(${PROJECT_NAME}_tests)
EOF

# Create stdafx.hpp
test -f include/stdafx.hpp || cat <<EOF >include/stdafx.hpp
#pragma once

#include <iostream>
EOF

# Create main.cpp
test -f src/main.cpp || cat <<EOF >src/main.cpp
#include "stdafx.hpp"

int main() {
    std::cout << "Hello, World!" << std::endl;
    return 0;
}
EOF

# Create lib.cpp
test -f src/lib.cpp || cat <<EOF >src/lib.cpp
#include "stdafx.hpp"

EOF

# Create test.cpp
test -f tests/test.cpp || cat <<EOF >tests/test.cpp
#include <gtest/gtest.h>

TEST(SampleTest, Test1) {
    EXPECT_EQ(1, 1);
}
EOF

git add .

echo "Project initialized successfully in directory: ${PROJECT_DIR}"
pushd build
cmake .. "-G${GENERATOR}"

popd
