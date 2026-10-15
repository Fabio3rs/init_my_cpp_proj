# GitHub Copilot Instructions — `init_my_cpp_proj`

> **Purpose**: Help Copilot (Chat, inline suggestions, and code review) work consistently in this repository. This repo provides a **Bash script** (`initcpp.sh`) to **bootstrap C/C++ projects with CMake**, optional GoogleTest, precompiled headers (PCH), and a GitHub Actions CI workflow.

---

## 1) Repository context

* **Script**: `initcpp.sh` — installs deps (optional), validates the project name/path, scaffolds the tree, initializes git, and configures a build folder.
* **Defaults**:

  * C++ standard: **C++20** (configurable with `-x`)
  * C standard: **C11** (configurable with `-c`)
  * Generator: **Ninja** (falls back to **Unix Makefiles** if Ninja is missing)
  * CMake minimum: `3.12` (enables **PCH** via `target_precompile_headers` when `CMake ≥ 3.16`)
  * Debug builds enable **sanitizers**; toolchains set **strict warnings** (GCC/Clang/MSVC) and treat warnings as errors (`-Werror`/`/WX`).
* **CI**: `.github/workflows/cmake-single-platform.yml` — Ubuntu 24.04, separate **Clang 18** and **GCC** jobs, builds with Ninja, runs the generated binary, and executes tests via `ctest`.

**Expected layout** after running `initcpp <name>`:

```
<project>/
├── CMakeLists.txt
├── .gitignore
├── include/
│   └── stdafx.hpp    # used as PCH when supported
├── src/
│   ├── main.cpp
│   └── lib.cpp
├── tests/
│   ├── CMakeLists.txt
│   └── test.cpp      # only if GTest is available
└── build/
```

---

## 2) How Copilot should help (priorities)

### A) Bash (`initcpp.sh`)

* Keep **strict handling**: `set -u`, `set -o pipefail`. Don’t add global `set -e`; the script supports **force** mode via `-f` (continue on errors) and **debug** via `-d` (verbose output).
* **Preserve CLI**: `-h -i -f -d -p <dir> -c <C_STANDARD> -x <CXX_STANDARD>` and existing semantics.
* **Package managers**: detect **apt-get**, **dnf**, **pacman**; install **cmake**, **git**, **ninja** and **gtest** (dev) idempotently with clear logs.
* Validate **paths** and **non-empty directories** safely; never overwrite user data silently.
* Keep error messages actionable and **exit codes** correct. If adding flags, update `usage()` and README accordingly.
* Avoid introducing new external deps (e.g., `jq`, `curl`) without a strong reason.

### B) CMake/C++ templates

* `cmake_minimum_required(VERSION 3.12)`; enable **PCH** with `target_precompile_headers` when available (≥3.16) using `include/stdafx.hpp`.
* Targets: a **static library** `${PROJECT_NAME}_lib` and an **executable** `${PROJECT_NAME}` that links that lib.
* Source discovery: `file(GLOB_RECURSE ...)` excluding `src/main.cpp` (keep current approach).
* **Warnings**: keep robust sets for GCC/Clang/MSVC; treat warnings as errors (`-Werror`/`/WX`).
* **Sanitizers (Debug)**: maintain the current list (ASan, UBSan, etc.) and keep frame pointers.
* **Tests**: `find_package(GTest QUIET)`; only enable tests when `GTest_FOUND`; prefer `gtest_discover_tests` when available.

### C) CI (GitHub Actions)

* Keep two jobs (Clang and GCC) on Ubuntu; steps: install toolchain → `initcpp -i` → `initcpp testproj` → `cmake -G Ninja -DCMAKE_BUILD_TYPE=Debug ..` → `ninja` → run binary → `ctest`.
* Don’t add new OSes (Windows/macOS) or expand matrices without agreement.

### D) Docs & UX

* Provide concise usage examples and next steps (build/run/test). Document any new flags immediately.

---

## 3) Style & quality

**Bash**

* Use `local` in functions; prefer `[[ ... ]]`; quote variables; avoid unnecessary subshells.
* Guard critical I/O with `|| { msg; exit 1; }` where appropriate.
* Keep `.gitignore` additions minimal; never remove current patterns without justification.

**C++ (generated)**

* Favor **RAII**, `std::vector`, smart pointers; avoid raw `new/delete`.
* Code must compile **warning-free under `-Werror`** and run cleanly under sanitizers.
* Keep tests **optional** (only when GTest is present) but include a minimal sample when enabled.

**CMake**

* Prefer target properties to global variables; avoid duplicated flags.
* Keep templates lean: avoid `FetchContent` or heavy dependencies by default.

---

## 4) "Don’t do" list

* Don’t change the policy about refusing to write into **non-empty directories**.
* Don’t make **GTest mandatory**.
* Don’t relax warning levels or remove sanitizers by default.
* Don’t rename the PCH file (`stdafx.hpp`) without a migration plan.

---

## 5) Copilot task blueprints (ready-to-use prompts)

* **Add `--no-git` flag** to skip `git init`: implement parsing, gate git steps, update `usage()` and README.
* **Optional package managers (`conan`/`vcpkg`)**: add `--with-conan/--with-vcpkg`; never enable by default; generate toolchain only if requested.
* **Alternative test framework**: add `--catch2` option that swaps GTest logic without changing the default.
* **Improve diagnostics & exit codes**: audit failure paths, standardize messages, ensure `exit 1` on critical failures.

---

## 6) CLI reference (for Copilot and reviewers)

**Usage**

```bash
initcpp <project-name>
```

**Options**

* `-h`                      Show help and usage examples
* `-c <standard>`           Set **C** standard (e.g., 11); default: 11
* `-x <standard>`           Set **C++** standard (11, 14, 17, 20, 23); default: 20
* `-p <path>`               Set custom project directory
* `-i`                      Install deps (cmake, git, ninja, gtest) for the detected distro
* `-f`                      Force continuation on errors
* `-d`                      Debug/verbose output

**Examples**

```bash
# Default settings (C++20)
initcpp my_awesome_project

# Custom C/C++ standards
initcpp -c 11 -x 23 future_project

# Custom project path
initcpp -p ~/dev path_app

# Debug output (useful for troubleshooting)
initcpp -d debug_project
```

---

## 7) How to validate changes suggested by Copilot

1. `chmod +x initcpp.sh && sudo cp initcpp.sh /usr/local/bin/initcpp` (or `~/.local/bin`).
2. `initcpp -i` to install dependencies (on supported distros).
3. `initcpp demo && cd demo/build && cmake -G Ninja -DCMAKE_BUILD_TYPE=Debug .. && ninja && ./demo && ctest`.
4. Push a PR to observe **both CI jobs** (Clang & GCC) passing.

---

## 8) Commit message conventions

* Use conventional prefixes: `feat:`, `fix:`, `docs:`, `ci:`, `refactor:`.
* Imperative tone; wrap body around 72 columns when possible.

---

## 9) Please ask before you…

* Raise `cmake_minimum_required` or change PCH strategy.
* Add new OS/platforms or CI matrices.
* Change sanitizer/warning policies or the directory structure.

> **TL;DR**: Keep the script **simple, robust, and portable**. It should generate modern C/C++ projects with CMake, optional PCH and tests, strong warnings and sanitizers by default—without adding unnecessary dependencies or breaking the validated CI flow.
