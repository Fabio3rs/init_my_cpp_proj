# Init my C++ project with CMake

This Bash script is designed to simplify the process of initializing C++ projects by creating a project directory structure, setting up necessary files like CMakeLists.txt, and installing dependencies with the configurations I prefer in my projects.

### Motivation
When starting a new C++ project, certain tasks are repetitive and time-consuming, such as creating directory structures, setting up build systems, and installing dependencies. This can be frustrating, especially when working on multiple projects. To streamline this process, I have created a script that automates the setup tasks, allowing developers to focus more on writing code and less on project setup.

As someone who regularly studies C++ and creates new projects, I understand the importance of being able to focus on the code rather than the project structure. That is why I created this script to automate the process of creating a new project.

### Features
- **🏗️ Automated Project Setup**: Create complete C++ project directory structure
- **⚙️ Modern CMake Configuration**: Generate optimized CMakeLists.txt with best practices
- **🛡️ Security & Quality**: Enable sanitizers and comprehensive warning flags by default
- **✅ Testing Ready**: Automatic GTest integration when available
- **🔧 Configurable**: Support for different C++ standards and custom project paths
- **🌐 Cross-Platform**: Support for multiple Linux package managers (apt, dnf, pacman)
- **📋 Modern Git Integration**: Initialize with main branch and proper .gitignore

Enabling sanitizers and warning flags in C++ offers significant benefits. Sanitizers detect common errors reducing security vulnerabilities. Warning flags promote best practices and code quality. By incorporating these tools, developers can enhance the security, reliability, and maintainability of their C++ codebases.
Since sanitizers run at runtime, it is essential to have automated tests in the codebase.

### Disclaimer
This Bash script is provided as-is, without any warranty or guarantee of its suitability for any particular purpose. While the script aims to automate the setup process for C++ projects, it may not cover all possible scenarios or configurations.

Users are advised to review and understand the script's functionality before running it, and to use it at their own risk. The author and contributors of this script shall not be held responsible for any damages or issues that arise from the use of this script.

By using this script, you agree to indemnify and hold harmless the author and contributors from any liability, damage, or loss arising from its use.

### Installation of the script
1. Clone the repository
```bash
git clone https://github.com/Fabio3rs/init_my_cpp_proj.git
```

2. Change the directory to the repository
```bash
cd init_my_cpp_proj
```

3. Make the script executable
```bash
chmod +x initcpp.sh
```

4. Add the script to the PATH
```bash
sudo cp initcpp.sh /usr/local/bin/initcpp
```
OR
```bash
cp initcpp.sh ~/.local/bin/initcpp
```

### Usage
Create a new C++ project with the project name as an argument:

```bash
initcpp <project-name>
```

#### Command Line Options

- `-h`: Display help message with usage examples
- `-c <standard>`: Set C++ standard version (11, 14, 17, 20, 23) - default is 20
- `-p <path>`: Custom directory path for the project
- `-i`: Install required dependencies (cmake, git, ninja, gtest)
- `-f`: Force script to continue even on errors
- `-d`: Enable debug mode with verbose output

#### Examples

```bash
# Create project with default settings (C++20)
initcpp my_awesome_project

# Create project with C++17 standard
initcpp -c 17 legacy_project

# Create project in custom directory
initcpp -p /home/user/projects/my_project awesome_project

# Install dependencies first, then create project
initcpp -i
initcpp my_project

# Create project with debug output
initcpp -d debug_project
```

#### Project Structure

The script creates the following structure:
```
my_project/
├── CMakeLists.txt          # Main build configuration
├── .gitignore              # Git ignore patterns
├── include/
│   └── common.hpp          # Common headers
├── src/
│   ├── main.cpp           # Application entry point
│   └── lib.cpp            # Library implementation
├── tests/
│   ├── CMakeLists.txt     # Test configuration
│   └── test.cpp           # Sample tests (if GTest available)
└── build/                 # Build directory (configured)
```

### What's New

Recent improvements include:
- **🔧 Enhanced CLI**: Better command-line parsing with C++ standard selection
- **🛠️ Cross-Platform**: Support for multiple Linux distributions (Ubuntu/Debian, Fedora/RHEL, Arch Linux)
- **🏗️ Robust Build**: Improved CMake configuration with better error handling
- **📚 Better Documentation**: Comprehensive README with examples and project structure
- **🧪 Smart Testing**: Automatic GTest detection with graceful fallback
- **🎯 Modern Practices**: Main branch initialization and organized sanitizer flags
- **⚡ Better UX**: Clear success messages and next-step instructions
