# Init my C++ project with CMake

A Bash script that creates a C++ project with the CMake configuration I use in my projects. It generates source files, a static library, an executable, and sample tests, initializes a Git repository, and configures the build directory.

## Motivation

I regularly create projects while studying C++. This script automates repetitive setup so I can spend more time writing code.

## Features

- Configurable C and C++ standards (C11 and C++20 by default).
- Compiler warnings with warnings treated as errors.
- Optional runtime sanitizers, enabled by default when configuring a fresh Debug build.
- Precompiled headers with CMake 3.16 or newer.
- GoogleTest integration and automatic test discovery when GoogleTest is available.
- Ninja builds, with Unix Makefiles as a fallback.
- Git initialization, a generated `.gitignore`, and an attempted initial commit.
- Dependency installation through `apt-get`, `dnf`, or `pacman`.

## Requirements

- Linux with Bash.
- Git.
- CMake 3.12 or newer. Sanitizers require at least 3.13; precompiled headers require at least 3.16. The selected language standard may require a newer CMake version.
- C and C++ compilers, such as GCC or Clang, supporting the selected standards (C11 and C++20 by default).
- Ninja or Make.
- Optional: GoogleTest development files for unit tests.
- For `-i`: a supported package manager and permission to install packages through `sudo`.

The generated CMake configuration includes MSVC warning flags, but the script targets Linux and its sanitizer flags are intended for GCC and Clang.

## Installation

Clone the repository:

```bash
git clone https://github.com/Fabio3rs/init_my_cpp_proj.git
cd init_my_cpp_proj
```

Install for your user:

```bash
mkdir -p "$HOME/.local/bin"
install -m 755 initcpp.sh "$HOME/.local/bin/initcpp"
export PATH="$HOME/.local/bin:$PATH"
```

If `~/.local/bin` is not already on your `PATH`, add the `export` line to your shell startup file (for example, `~/.bashrc`).

Alternatively, install system-wide:

```bash
sudo install -m 755 initcpp.sh /usr/local/bin/initcpp
```

You can also run the script directly without installing it:

```bash
bash initcpp.sh my_project
```

### Installing dependencies

```bash
initcpp -i
```

This installs missing CMake, Git, and Ninja commands, plus the GoogleTest development package, using the first supported package manager found (`apt-get`, `dnf`, or `pacman`). It exits after installation without creating a project. Install your C and C++ compilers separately; `-i` does not install them.

## Usage

```bash
initcpp [options] <project_name>
```

Place options before the project name. Names may contain letters, numbers, underscores, and hyphens, but no spaces. Starting with a letter or underscore is recommended.

The destination must be absent or an empty directory. By default, it is named after the project in the current directory. With `-p`, the supplied path is the exact destination; the project name is not appended.

### Command-line options

| Option | Description |
| --- | --- |
| `-h` | Display usage information. Currently exits with status 1. |
| `-c <standard>` | Set the C standard (default: `11`). |
| `-x <standard>` | Set the C++ standard (default: `20`). |
| `-p <path>` | Set the project directory (default: `<project_name>`). |
| `-i` | Install dependencies and exit. No project name is required. |
| `-f` | Continue after some command failures. Explicit validation and CMake configuration failures still stop the script. |
| `-d` | Enable Bash command tracing for project creation. |

### Examples

```bash
# Create a project using C++20
initcpp my_project

# Use C++17
initcpp -x 17 legacy_project

# Create ~/projects/my_project with an executable named awesome_project
initcpp -p "$HOME/projects/my_project" awesome_project

# Show executed commands
initcpp -d debug_project

# Select both language standards and a destination
initcpp -c 11 -x 23 -p "$HOME/dev/modern_project" future_project
```

Use `-x` to select the C++ standard; `-c` only changes the C standard. The `-d` option enables script tracing, not a CMake Debug build.

### Generated project structure

```text
my_project/
├── .git/
├── .gitignore
├── CMakeLists.txt
├── include/
│   └── stdafx.hpp         # Precompiled header
├── src/
│   ├── main.cpp           # Hello, World! executable
│   └── lib.cpp            # Static library placeholder
├── tests/
│   ├── CMakeLists.txt
│   └── test.cpp           # Sample GoogleTest test
└── build/                 # Configured by the script
```

Test files are always generated. If CMake cannot find GoogleTest, test targets are disabled. The initial Git branch follows your Git configuration. If Git cannot create the initial commit (for example, because your name or email is unset), the script continues with the files staged.

## Building and running

After the script successfully configures the project:

```bash
cd my_project
cmake --build build
./build/my_project

# Run tests if GoogleTest was found
(cd build && ctest --output-on-failure)
```

The script selects Ninja if it is available when the script starts; otherwise, it selects Unix Makefiles. It configures the project but does not compile it or run tests.

### Debug builds and sanitizers

The initial configuration does not set `CMAKE_BUILD_TYPE`, so sanitizers are off by default. To enable them in the existing build directory, set both options explicitly:

```bash
cmake -S . -B build -DCMAKE_BUILD_TYPE=Debug -DENABLE_SANITIZERS=ON
cmake --build build
./build/my_project
(cd build && ctest --output-on-failure)
```

`ENABLE_SANITIZERS` is cached by CMake. Changing only the build type after the initial configuration does not change its cached value. Sanitizers help detect errors at runtime, so run your executable and tests to benefit from them.

To configure a Release build without sanitizers:

```bash
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release -DENABLE_SANITIZERS=OFF
cmake --build build
```

The `cmake -S . -B build` examples require CMake 3.13 or newer. With CMake 3.12, configure from inside `build` using `cmake ..` and the desired options, with sanitizers disabled.

### Tests and source files

To disable test targets explicitly:

```bash
cmake -S . -B build -DENABLE_TESTS=OFF
```

After installing GoogleTest, reconfigure with `-DENABLE_TESTS=ON` and rebuild to enable the sample test.

The generated configuration collects library sources from `src/*.cpp` recursively, excluding `src/main.cpp`. Rerun CMake after adding or removing source files so the build includes the changes.

## License

This project is distributed under the [MIT License](LICENSE), without warranty. Review the script before running it, especially its dependency installation commands.
