# Init my C++ project with CMake

This Bash script is designed to simplify the process of initializing C++ projects by creating a project directory structure, setting up necessary files like CMakeLists.txt, and installing dependencies with the configurations I prefer in my projects.

### Motivation
When starting a new C++ project, certain tasks are repetitive and time-consuming, such as creating directory structures, setting up build systems, and installing dependencies. This can be frustrating, especially when working on multiple projects. To streamline this process, I have created a script that automates the setup tasks, allowing developers to focus more on writing code and less on project setup.

As someone who regularly studies C++ and creates new projects, I understand the importance of being able to focus on the code rather than the project structure. That is why I created this script to automate the process of creating a new project.

### Features
- Create a project directory structure
- Generate CMakeLists.txt file
- By default sanitize and enable warnings in the CMakeLists.txt file
- Add a sample test file

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
To create a new C++ project, run the script with the project name as an argument. The script will create a new directory with the project name and set up the project structure and files.

```bash
initcpp <project-name>
```
