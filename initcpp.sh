#!/bin/bash

# C++ Project Initialization Script
# This script creates a new C++ project with CMake, including sanitizers, tests, and modern C++ practices.

# Exit on error by default, can be overridden with -f flag
set -e

# Function to display usage information
usage() {
    echo "Usage: $0 [-h] [-p <PROJECT_PATH>] [-c <CXX_STANDARD>] [-i] [-f] [-d] [project_name]" 1>&2;
    echo "Options:" 1>&2;
    echo "    -h                   Display this help message." 1>&2;
    echo "    -p <PROJECT_PATH>    Custom path for the project directory." 1>&2;
    echo "    -c <CXX_STANDARD>    C++ standard version (default: 20)." 1>&2;
    echo "    -i                   Install dependencies." 1>&2;
    echo "    -f                   Force script to proceed even with errors." 1>&2;
    echo "    -d                   Enable script debugging." 1>&2;
    echo "    project_name         Name of the project to create." 1>&2;
    echo "" 1>&2;
    echo "Examples:" 1>&2;
    echo "    $0 my_project                    # Create project with default settings" 1>&2;
    echo "    $0 -c 17 my_project             # Create project with C++17 standard" 1>&2;
    echo "    $0 -p /custom/path my_project   # Create project in custom directory" 1>&2;
    exit 1;
}

# Function to validate project name
validate_project_name() {
    local project_name="$1"
    
    if [[ -z "${project_name}" ]]; then
        echo "Error: Project name is required." >&2
        return 1
    fi

    if [[ "${project_name}" == *" "* ]]; then
        echo "Error: Project name cannot contain spaces." >&2
        return 1
    fi

    # Check for invalid characters that might cause issues
    if [[ "${project_name}" =~ [^a-zA-Z0-9._-] ]]; then
        echo "Warning: Project name contains special characters that might cause issues." >&2
        echo "Recommended to use only letters, numbers, dots, hyphens, and underscores." >&2
    fi
    
    return 0
}

install_deps() {
    echo "Installing dependencies..."
    
    # Detect package manager
    if command -v apt-get &> /dev/null; then
        echo "Using apt-get (Debian/Ubuntu)"
        sudo apt-get update
        
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

        # Install GTest
        echo "Installing Google Test..."
        sudo apt-get install -y libgtest-dev
        
    elif command -v dnf &> /dev/null; then
        echo "Using dnf (Fedora/RHEL)"
        
        if ! command -v cmake &> /dev/null; then
            echo "Installing CMake..."
            sudo dnf install -y cmake
        fi

        if ! command -v git &> /dev/null; then
            echo "Installing Git..."
            sudo dnf install -y git
        fi

        if ! command -v ninja &> /dev/null; then
            echo "Installing Ninja..."
            sudo dnf install -y ninja-build
        fi

        echo "Installing Google Test..."
        sudo dnf install -y gtest-devel
        
    elif command -v pacman &> /dev/null; then
        echo "Using pacman (Arch Linux)"
        
        if ! command -v cmake &> /dev/null; then
            echo "Installing CMake..."
            sudo pacman -S --noconfirm cmake
        fi

        if ! command -v git &> /dev/null; then
            echo "Installing Git..."
            sudo pacman -S --noconfirm git
        fi

        if ! command -v ninja &> /dev/null; then
            echo "Installing Ninja..."
            sudo pacman -S --noconfirm ninja
        fi

        echo "Installing Google Test..."
        sudo pacman -S --noconfirm gtest
        
    else
        echo "Error: Unsupported package manager. Please install cmake, git, ninja, and gtest manually." >&2
        exit 1
    fi
    
    echo "Dependencies installed successfully!"
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
        c)
            DEFAULT_CXX_STD=${OPTARG}
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

# Set error handling based on flag
if [[ ${IGNORE_SCRIPT_ERRORS} -eq 1 ]]; then
    set +e  # Disable exit on error
    echo "Warning: Error handling disabled. Script will continue on errors."
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

# Validate project name
if ! validate_project_name "${PROJECT_NAME}"; then
    usage
fi

# Check if directory exists and is not empty
if [[ -d "${PROJECT_DIR}" ]] && [[ "$(ls -A "${PROJECT_DIR}" 2>/dev/null)" ]]; then
    echo "Directory ${PROJECT_DIR} already exists and is not empty."
    exit 1
fi

# Create project directory
mkdir -p "${PROJECT_DIR}/include" "${PROJECT_DIR}/src" "${PROJECT_DIR}/build" "${PROJECT_DIR}/tests"

# Initialize Git repository
cd "${PROJECT_DIR}" || exit
git init --initial-branch=main 2>/dev/null || git init  # Fallback for older git versions
if [[ $(git branch --show-current 2>/dev/null) != "main" ]]; then
    git branch -m main 2>/dev/null || true  # Rename to main if not already
fi

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
    find_package(GTest QUIET)

    if(GTest_FOUND)
        message(STATUS "GTest found, enabling tests")
        include(GoogleTest)
        add_subdirectory(tests)
    else()
        message(WARNING "GTest not found, tests will be disabled. Install GTest to enable testing.")
        set(ENABLE_TESTS OFF)
    endif()
endif()

if(ENABLE_SANITIZERS)
    # Common sanitizer flags for better security and debugging
    set(SANITIZER_FLAGS
        -fno-omit-frame-pointer
        -fsanitize=address
        -fsanitize=alignment
        -fsanitize=bool
        -fsanitize=bounds
        -fsanitize=enum
        -fsanitize=float-cast-overflow
        -fsanitize=float-divide-by-zero
        -fsanitize=integer-divide-by-zero
        -fsanitize=leak
        -fsanitize=nonnull-attribute
        -fsanitize=pointer-compare
        -fsanitize=pointer-overflow
        -fsanitize=pointer-subtract
        -fsanitize=return
        -fsanitize=returns-nonnull-attribute
        -fsanitize=shift
        -fsanitize=signed-integer-overflow
        -fsanitize=undefined
        -fsanitize=unreachable
        -fsanitize=vla-bound
        -fsanitize=vptr
        -g
    )
    
    add_compile_options(\${SANITIZER_FLAGS})
    add_link_options(\${SANITIZER_FLAGS})

    if(\${CMAKE_CXX_COMPILER_ID} STREQUAL "Clang")
        message(STATUS "Setting Clang-specific sanitizer flags")
        add_compile_options(-fsanitize=implicit-conversion -fsanitize=unsigned-integer-overflow)
        add_link_options(-fsanitize=implicit-conversion -fsanitize=unsigned-integer-overflow)
    endif()
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

# Tests are only added if GTest is found (handled in ENABLE_TESTS section above)
EOF

test -f tests/CMakeLists.txt || cat <<EOF >tests/CMakeLists.txt
add_executable(${PROJECT_NAME}_tests test.cpp)
target_link_libraries(${PROJECT_NAME}_tests ${PROJECT_NAME}_lib GTest::GTest GTest::Main)
gtest_discover_tests(${PROJECT_NAME}_tests)
EOF

# Create common.hpp
test -f include/common.hpp || cat <<EOF >include/common.hpp
#pragma once

// Common standard library includes
#include <iostream>
#include <string>
#include <vector>
#include <memory>

// Add your project-specific common includes here

EOF

# Create main.cpp
test -f src/main.cpp || cat <<EOF >src/main.cpp
#include "common.hpp"

int main() {
    std::cout << "Hello, World!" << std::endl;
    return 0;
}
EOF

# Create lib.cpp
test -f src/lib.cpp || cat <<EOF >src/lib.cpp
#include "common.hpp"

// Add your library implementation here

EOF

# Create test.cpp
test -f tests/test.cpp || cat <<EOF >tests/test.cpp
#include <gtest/gtest.h>

TEST(SampleTest, Test1) {
    EXPECT_EQ(1, 1);
}
EOF

# Configure git identity for the initial commit (placeholder values for CI environments)
git config user.email "initcpp@example.com"
git config user.name "InitCpp Script"

git add .
git commit -m "Initial project setup with CMake and modern C++ configuration"

echo ""
echo "✅ Project '${PROJECT_NAME}' initialized successfully!"
echo "📁 Location: ${PROJECT_DIR}"
echo "🏗️  Build system: CMake with ${GENERATOR}"
echo "⚙️  C++ Standard: C++${DEFAULT_CXX_STD}"
echo ""
echo "Next steps:"
echo "  1. cd ${PROJECT_DIR}"
echo "  2. cmake --build build        # Build the project"
echo "  3. ./build/${PROJECT_NAME}    # Run the executable"
echo ""

# Configure the build
pushd build > /dev/null
echo "Configuring build system..."
if cmake .. "-G${GENERATOR}"; then
    echo "✅ Build configuration successful!"
    echo ""
    echo "To build and run your project:"
    echo "  cd ${PROJECT_DIR}"
    echo "  cmake --build build"
    echo "  ./build/${PROJECT_NAME}"
else
    echo "❌ Build configuration failed. You can manually run 'cmake --build build' later."
    exit 1
fi
popd > /dev/null
