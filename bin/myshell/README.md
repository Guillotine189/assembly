# MyShell

An interactive Linux shell written in x86-64 assembly using NASM. The project focuses on low-level terminal interaction, command parsing, input editing, and command construction without relying on a high-level language.

## Requirements

1. **Linux on x86-64**
2. **NASM** assembler
3. GNU **`ld`** linker
4. **Bash** — Required to run the provided build script (`build_myshell.sh`)

## Installation

#### 1. Clone the repository

```bash
git clone https://github.com/Guillotine189/assembly.git
```

#### 2. CD into folder

```bash
cd ./assembly/bin/myshell
```

#### 3. Give installation script permission to execute

```bash
chmod +x build_myshell.s
```

#### 4. Build the program

```bash
./build_myshell.s
```

## Run

```bash
./myshell
```

## Features

**1: Interactive command-line**: input with cursor movement and editing.

**2: Command history** ( Fixed size, can be changed by editing the value of 'capacity_arr' symbolic constant inside history.s file and rebuilding the project).

**3: Support for expansion**: History commands, shell env vars and last command exit_code_status can be expanded.

  input  | Replaced by |
|-------------|------------|
| `!!` | `Previous command, if exists.` |
| `!4` | `Command number 4 in history, if exists.` |
| `$SHELL` | `The 'SHELL' env variable, if exists.` |
| `$?` | `The exit status code of last command` |

**Expansions are not performed inside single quotes.**

**4. Auto-completion:** Press `Tab` once to auto-complete commands (built-in commands and executables found in directories listed in `$PATH`) and file names. Press `Tab` twice to display all available completion options.

**5: Built in commands**: `cd, export, unset, history, etc`.

**6: Chained Commands:** Supports executing multiple commands chained together.

1. Pipes (|).
2. Input and output redirection (<, >).
3. Append output redirection (>>).

**7: Passing Environment Variables:** Supports passing environment variable assignments directly to commands
(eg: `FOO=bar command`).

**8: Quoted input handling for parsing arguments.**
1. Pipes (|).
2. Input and output redirection (<, >).
3. Append output redirection (>>).
4. Environment assignments. "foo=bar"

**9: Heap Allocator Debugging Shortcuts**

Because I implemented everything from scratch, including the heap allocator, these shortcuts display information about heap segments managed by my allocator.

| Shortcut | Action |
|---|---|
| `Alt + ↑` | `Print basic myMalloc information` |
| `Alt + ←` | `Print summarized segment information` |
| `Alt + ↓` | `Display a visualization of the 3 free lists mentained by myMalloc` |
| `Alt + →` | `Print detailed segment information` |

This is more of a debugging feature. But it's fun to look at (atleast for me).


## Implementation

### 1. Terminal Input

The input editor manages interactive input and cursor movement using terminal control sequences. It includes logic for redrawing the input line and handling terminal dimensions.

### 2. Processing input

#### 2.1. Expansion
The expansion-code expands the SHELL env variables and history comamnds.

####  2.2. Tokenization and Parsing
The parsing-code uses this expanded string and resolves the quotes and assigns each possible-operator a value weather it is to be treated as a operator or not.

The tokenizer then converts it into tokens representing words(eg: "grep", "--colo=auto") and shell operators(eg: ">", "|"). 
Supported token types include words, pipes, input redirection, output redirection, append redirection, and environment assignments.

Example for command:
```bash
foo=bar env | grep SHELL > output.txt
```
#### Tokens Generated
| Token Value | Token Type |
|-------------|------------|
| `foo=bar` | `env_assignemnt` |
| `env` | `word` |
| `\|` | `pipe` |
| `grep` | `word` |
| `SHELL` | `word` |
| `>` | `redirect_out` |
| `output.txt` | `word` |

### 3. Command Construction

The command-generation code processes tokens and builds command structures containing command names, argument array, environment array, and input/output redirection details.

Example of a command struct for command 

```bash
foo=bar env | grep SHELL > output.txt
```

**2 commands mean, 2 command structs will be generated**

|  Command Struct 1 Var  | Value |
|-------------|------------|
| `commmand_name` | `env` |
| `argc_array` | `env, NULL` |
| `argv_arr` | `foo=bar, NULL` |
|`redirect_in` | `default` |
|`redirect_out` | `pipe` |


|  Command Struct 2 Var  | Value |
|-------------|------------|
| `commmand_name` | `grep` |
| `argc_array` | `grep`, NULL |
| `argv_arr` | `NULL` |
|`redirect_in` | `pipe` |
|`redirect_out` | `default` |

### 4. Command Execution

1: Create a Common_envp_array conatining all the shell_env variables

2: Loop the execution process:
Check total commands and creates pipes for redirection for communication.
forks.

#### Child Process

0: **Changes the pgid** to pgid of entire group.

1: **Reads the command structure** to retrieve the command name, arguments, environment variables, and redirection information.

2: **Applies I/O redirections** using `dup2()` to redirect standard input or standard output as specified by the command.

3: **Populates the environment array** with the shell's environment variables.

4: **Waits for a signal** from **Parent**

5: **Checks for built-in commands** to determine whether the command can be handled internally by the shell.

6: Decides and **Searches for the executable** by checking the directories listed in the **`$PATH` environment variable**.

7: Adds the **`_=`** environment variable to the common/specific environment array, setting its value to the command's executable path (`_=command_path`).

8: **Executes the command**.

Final command structs before execution for command :

```bash
foo=bar env | grep SHELL > output.txt
```

|  Command Struct 1 Var  | Value |
|-------------|------------|
| `commmand_name` | `/bin/env` |
| `argc_array` | `env, NULL` |
| `argv_arr` | `foo=bar, `*ALL_SHELL_ENV_VARS*`, _=/bin/env, NULL` |
|`redirect_in` | `default` |
|`redirect_out` | `pipe` |


|  Command Struct 2 Var  | Value |
|-------------|------------|
| `commmand_name` | `/bin/grep` |
| `argc_array` | `grep`, NULL |
| `argv_arr` | *ALL_SHELL_ENV_VARS*`, _=/bin/grep, NULL` |
|`redirect_in` | `pipe` |
|`redirect_out` | `default` |

#### Parent Process

1: **Loops** and creates all child processes.

2: **Puts child Pgid** into **foreground**

3: **Give signal** to child processes to start execution.

4: **Wait and reap** all child processes

5: **Put Shell** back into **foreground**








### Comparing to bash, things this doesn't support

-  **Multiple redirections**

  ```bash
  ls > output1.txt > output2.txt
  ```

  **Behavior:**
  Only `output2.txt` receives the command's standard output because the second output redirection overrides the first.

-  **Alias.**: Aliases are not supported yet

-  **Shell variables.**: Shell variables are not supported yet.

-  **Background jobs**: Using `&` to run commands in the background is not supported.

-  **&& operator**: Running a command only if the previous one succeeds is not supported.

-  **source** bic command:  this shell doesn't parse Bash syntax like if, fi, etc.

-  **Limited Autocompletion**:  as I can't implement suggestions for options specific to individual commands.

-  **UTF-8 characters**: only ASCII characters are supported, so UTF-8 characters won't work properly.

-  And there are many more limitations that I can't list here. There's still plenty of room for improvement!


---
The goal of this project is to understand how a shell works internally by designing and implementing one from scratch. The shell is written entirely in x86-64 assembly, without relying on the C standard library. This is a deliberate choice so i an get an idea of low-level system programming and become more familiar with Linux system calls.