#!/bin/bash
# Enable strict variable handling and catch errors in pipelines.
set -u
set -o pipefail

# Function to display usage information.
usage() {
    cat <<EOF
Usage: $0 [-h] [-i] [-f] [-d] [-p <project_directory>] [-c <C_STANDARD>] [-x <CXX_STANDARD>] <project_name>

Options:
  -h                    Display this help message.
  -i                    Install dependencies.
  -f                    Force script to proceed even if errors occur.
  -d                    Enable debugging.
  -p <project_directory>
                        Specify the project directory (defaults to <project_name>).
  -c <C_STANDARD>       Set the default C standard (default: 11).
  -x <CXX_STANDARD>     Set the default C++ standard (default: 20).
EOF
    exit 1
}

# Function to install dependencies.
install_deps() {
    # Detect package manager and install dependencies accordingly
    if command -v apt-get &>/dev/null; then
        echo "Detected apt-get (Ubuntu/Debian)..."
        # Update package list first
        sudo apt-get update

        # Install CMake if missing.
        if ! command -v cmake &>/dev/null; then
            echo "Installing CMake..."
            sudo apt-get install -y cmake
        fi

        # Install Git if missing.
        if ! command -v git &>/dev/null; then
            echo "Installing Git..."
            sudo apt-get install -y git
        fi

        # Install Ninja if missing.
        if ! command -v ninja &>/dev/null; then
            echo "Installing Ninja..."
            sudo apt-get install -y ninja-build
        fi

        # Install GoogleTest development files.
        sudo apt-get install -y libgtest-dev

    elif command -v dnf &>/dev/null; then
        echo "Detected dnf (Fedora/RHEL)..."

        # Install CMake if missing.
        if ! command -v cmake &>/dev/null; then
            echo "Installing CMake..."
            sudo dnf install -y cmake
        fi

        # Install Git if missing.
        if ! command -v git &>/dev/null; then
            echo "Installing Git..."
            sudo dnf install -y git
        fi

        # Install Ninja if missing.
        if ! command -v ninja &>/dev/null; then
            echo "Installing Ninja..."
            sudo dnf install -y ninja-build
        fi

        # Install GoogleTest development files.
        sudo dnf install -y gtest-devel

    elif command -v pacman &>/dev/null; then
        echo "Detected pacman (Arch Linux)..."

        # Update package database first
        sudo pacman -Sy

        # Install CMake if missing.
        if ! command -v cmake &>/dev/null; then
            echo "Installing CMake..."
            sudo pacman -S --noconfirm cmake
        fi

        # Install Git if missing.
        if ! command -v git &>/dev/null; then
            echo "Installing Git..."
            sudo pacman -S --noconfirm git
        fi

        # Install Ninja if missing.
        if ! command -v ninja &>/dev/null; then
            echo "Installing Ninja..."
            sudo pacman -S --noconfirm ninja
        fi

        # Install GoogleTest development files.
        sudo pacman -S --noconfirm gtest

    else
        echo "Warning: No supported package manager found (apt-get, dnf, pacman)."
        echo "Please install the following packages manually:"
        echo "- cmake"
        echo "- git"
        echo "- ninja-build (or ninja)"
        echo "- gtest/libgtest-dev"
        exit 1
    fi
}

# Default configuration.
IGNORE_SCRIPT_ERRORS=0
SCRIPT_DEBUG=0

# Default standards.
DEFAULT_CXX_STD="20"
DEFAULT_C_STD="11"

ENABLE_C_EXTENSIONS="ON"
ENABLE_CXX_EXTENSIONS="ON"

# Set default generator to Ninja (fallback to Unix Makefiles if Ninja is not available).
GENERATOR="Ninja"
if ! command -v ninja &>/dev/null; then
    GENERATOR="Unix Makefiles"
fi

PROJECT_DIR=""

# Parse command-line options.
while getopts ":hip:fdc:x:" opt; do
    case "${opt}" in
        h)
            usage
            ;;
        i)
            install_deps
            exit 0
            ;;
        p)
            PROJECT_DIR=${OPTARG}
            ;;
        f)
            IGNORE_SCRIPT_ERRORS=1
            ;;
        d)
            SCRIPT_DEBUG=1
            ;;
        c)
            DEFAULT_C_STD=${OPTARG}
            ;;
        x)
            DEFAULT_CXX_STD=${OPTARG}
            ;;
        \?)
            echo "Invalid option: -$OPTARG" >&2
            usage
            ;;
        :)
            echo "Option -$OPTARG requires an argument." >&2
            usage
            ;;
    esac
done
shift $((OPTIND - 1))

# Enable debugging if requested.
if [[ ${SCRIPT_DEBUG} -eq 1 ]]; then
    set -x
fi

# Exit on error unless we are forcing errors to be ignored.
if [[ ${IGNORE_SCRIPT_ERRORS} -eq 0 ]]; then
    set -e
fi

# Ensure a project name is provided.
if [[ $# -lt 1 ]]; then
    echo "Error: Project name is required." >&2
    usage
fi

PROJECT_NAME="$1"
shift

# Function to validate project name.
validate_project_name() {
    local project_name="$1"

    # Check if project name is empty
    if [[ -z "$project_name" ]]; then
        echo "Error: Project name cannot be empty." >&2
        return 1
    fi

    # Check if project name contains spaces
    if [[ "$project_name" =~ \  ]]; then
        echo "Error: Project name cannot contain spaces." >&2
        return 1
    fi

    # Check if project name contains invalid characters
    if [[ ! "$project_name" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        echo "Error: Project name can only contain letters, numbers, underscores, and hyphens." >&2
        return 1
    fi

    # Check if project name starts with a letter or underscore (good C++ practice)
    if [[ ! "$project_name" =~ ^[a-zA-Z_] ]]; then
        echo "Warning: Project name should start with a letter or underscore for better C++ compatibility." >&2
    fi

    return 0
}

# Validate the project name.
validate_project_name "${PROJECT_NAME}" || exit 1

# If no project directory was specified, default to the project name.
if [[ -z "${PROJECT_DIR}" ]]; then
    PROJECT_DIR="${PROJECT_NAME}"
fi

# Check if the project directory exists and is not empty.
if [[ -d "${PROJECT_DIR}" ]]; then
    if [[ -n "$(ls -A "${PROJECT_DIR}" 2>/dev/null)" ]]; then
        echo "Error: Directory '${PROJECT_DIR}' is not empty." >&2
        exit 1
    fi
fi

# Create the project directory structure.
mkdir -p "${PROJECT_DIR}/include" "${PROJECT_DIR}/src" "${PROJECT_DIR}/build" "${PROJECT_DIR}/tests"

# Initialize a new Git repository.
cd "${PROJECT_DIR}" || { echo "Failed to enter directory ${PROJECT_DIR}"; exit 1; }
git init

# Create .gitignore if it doesn't already exist.
if [[ ! -f .gitignore ]]; then
    cat <<'EOF' > .gitignore
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
fi

# Create the main CMakeLists.txt if it does not exist.
if [[ ! -f CMakeLists.txt ]]; then
    cat <<EOF > CMakeLists.txt
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
    add_compile_options(-Wall -Werror -Wextra -Wformat-security -Wconversion -Wsign-conversion -Wno-gnu -Wno-gnu-statement-expression)
elseif (\${CMAKE_CXX_COMPILER_ID} STREQUAL "MSVC")
    message(STATUS "Setting MSVC flags")
    add_compile_options(/W4 /WX)
elseif (\${CMAKE_CXX_COMPILER_ID} STREQUAL "Clang")
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

    if (\${CMAKE_CXX_COMPILER_ID} STREQUAL "Clang")
        message(STATUS "Setting Clang-specific sanitizer flags")
        add_compile_options(-fsanitize=implicit-conversion -fsanitize=unsigned-integer-overflow)
        add_link_options(-fsanitize=implicit-conversion -fsanitize=unsigned-integer-overflow)
    endif()
endif()

# Add the include directory.
include_directories(include)

# Enable precompiled headers if supported
if(CMAKE_VERSION VERSION_GREATER_EQUAL "3.16")
    # Modern CMake precompiled header support
    set(PCH_HEADER "include/stdafx.hpp")
    if(EXISTS "\${CMAKE_CURRENT_SOURCE_DIR}/\${PCH_HEADER}")
        message(STATUS "Using precompiled header: \${PCH_HEADER}")
        # We'll set this after creating the targets
    endif()
endif()

# Function to filter out excluded files.
function(filter_out excluded output)
    set(result "")
    foreach(file \${\${output}})
        if(NOT "\${file}" IN_LIST \${excluded})
            list(APPEND result \${file})
        endif()
    endforeach()
    set(\${output} "\${result}" PARENT_SCOPE)
endfunction()

# Gather all source files.
file(GLOB_RECURSE SOURCES "\${CMAKE_CURRENT_SOURCE_DIR}/src/*.cpp")
set(EXCLUDE_FILES "\${CMAKE_CURRENT_SOURCE_DIR}/src/main.cpp")
filter_out(EXCLUDE_FILES SOURCES)

message(STATUS "Sources: \${SOURCES}")

add_library(${PROJECT_NAME}_lib STATIC \${SOURCES})
add_executable(${PROJECT_NAME} "src/main.cpp")
target_link_libraries(${PROJECT_NAME} ${PROJECT_NAME}_lib)

# Set up precompiled headers if supported and available
if(CMAKE_VERSION VERSION_GREATER_EQUAL "3.16" AND EXISTS "\${CMAKE_CURRENT_SOURCE_DIR}/include/stdafx.hpp")
    target_precompile_headers(${PROJECT_NAME}_lib PRIVATE "include/stdafx.hpp")
    target_precompile_headers(${PROJECT_NAME} REUSE_FROM ${PROJECT_NAME}_lib)
    message(STATUS "Precompiled headers enabled for faster compilation")
endif()

if(ENABLE_TESTS AND GTest_FOUND)
    add_subdirectory(tests)
endif()
EOF
fi

# Create tests/CMakeLists.txt if it doesn't exist.
if [[ ! -f tests/CMakeLists.txt ]]; then
    cat <<EOF > tests/CMakeLists.txt
add_executable(${PROJECT_NAME}_tests test.cpp)
target_link_libraries(${PROJECT_NAME}_tests ${PROJECT_NAME}_lib GTest::GTest GTest::Main)
gtest_discover_tests(${PROJECT_NAME}_tests)
EOF
fi

# Create sample header and source files if they do not exist.
if [[ ! -f include/stdafx.hpp ]]; then
    cat <<EOF > include/stdafx.hpp
#pragma once
#include <iostream>
EOF
fi

if [[ ! -f src/main.cpp ]]; then
    cat <<EOF > src/main.cpp
#include "stdafx.hpp"

int main() {
    std::cout << "Hello, World!" << std::endl;
    return 0;
}
EOF
fi

if [[ ! -f src/lib.cpp ]]; then
    cat <<EOF > src/lib.cpp
#include "stdafx.hpp"

// Library implementation.
EOF
fi

if [[ ! -f tests/test.cpp ]]; then
    cat <<EOF > tests/test.cpp
#include <gtest/gtest.h>

TEST(SampleTest, BasicTest) {
    EXPECT_EQ(1, 1);
}
EOF
fi

# Stage and (optionally) commit the initial files.
git add .
git commit -m "Initial project structure" || true

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
if command -v ctest &>/dev/null && [[ -d "tests" ]]; then
echo "  4. cd build && ctest          # Run tests (if available)"
fi
echo ""

# Configure the project with CMake.
pushd build > /dev/null
echo "Configuring build system with ${GENERATOR}..."
if cmake .. "-G${GENERATOR}"; then
    echo "✅ Build configuration successful!"
    echo ""
    echo "Ready to build! Run 'cmake --build build' to compile your project."
else
    echo "❌ Build configuration failed. Please check the error messages above."
    exit 1
fi
popd > /dev/null
