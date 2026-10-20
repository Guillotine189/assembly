# MyShell

An interactive Linux shell written in x86-64 assembly using NASM. This project focuses on low-level terminal interaction, command parsing, input editing, and command construction without relying on any high-level language.

## Requirements

1. **Operating System: `Linux on x86-64 architecture.`**
2. **Minimum Linux Kernel Version: `5.8 (released August 2020).`**
3. Assembler: **`NASM`** 
4. GNU linker: **`ld`** 
5. Build Tool: **`GNU Make`** 

## Installation

#### 1. Clone the repository

```bash
git clone https://github.com/Guillotine189/assembly.git
```

#### 2. CD into folder

```bash
cd ./assembly/bin/myshell
```

#### 3. Build the program

```bash
make all
```


## Run

```bash
./myshell
```

~~**Recommendation:** It is recommended to set `myshell` as your default shell in Konsole, as it has unexpected crashes specifically if ran noramlly using bash.~~

## Features

**1: Interactive command-line**: input with cursor movement and editing.

**2: Command history**: In-memory and Fixed size ( Size can be changed by editing the value of 'history_size' symbolic constant inside ./src/dep/history.s file and rebuilding the project).

**3: Support for expansion**: History commands, shell env vars and last command exit_code_status can be expanded.

  input  | Replaced by |
|-------------|------------|
| `!!` | Previous command, if exists. |
| `!4` | Command number 4 in history, if exists. |
| `$SHELL` | The `$SHELL` env variable, if exists. |
| `$?` | The exit status code of last command |

**Expansions are not performed inside single quotes.**

**4. Auto-completion:** Press `Tab` once to auto-complete commands (built-in commands and executables found in directories listed in `$PATH`) and file names. Press `Tab` twice to display all available completion options.

**5: Built in commands**: `cd`, `export`, `unset`, `history`, `etc`.

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
| `Alt + ↑` | Print basic myMalloc information |
| `Alt + ←` | Print summarized segment information |
| `Alt + ↓` | Display a visualization of the 3 free lists mentained by myMalloc |
| `Alt + →` | Print detailed segment information |

This is more of a debugging feature. But it's fun to look at (atleast for me).


## Implementation

### 1. Terminal Input

The input editor manages interactive input and cursor movement using ANSI seq. It includes logic for redrawing the input line and cursor.

### 2. Processing input

#### 2.1. Expansion
The expansion-code expands the SHELL env variables and history comamnds. Then adds it to history.

####  2.2. Tokenization and Parsing
The parsing-code uses this expanded string and resolves the quotes and assigns each possible-operator a value weather it is to be treated as a operator or not. (if an operator is inside qutes, it's treated as a normal char)

The tokenizer then converts it into tokens representing words(eg: "grep", "--colo=auto") and shell operators(eg: ">", "|"). 
Supported token types include words, pipes, input redirection, output redirection, append redirection, and environment assignments.

Example for command:
```bash
foo=bar env | grep SHELL > output.txt
```
#### Tokens Generated
| Token Value | Token Type |
|-------------|------------|
| `foo=bar` | `env_assignment` |
| `env` | `word` |
| `NULL` | `pipe` |
| `grep` | `word` |
| `SHELL` | `word` |
| `NULL` | `redirect_out` |
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
| `argv_array` | `env, NULL` |
| `envp_array` | `foo=bar, NULL` |
| `redirect_in` | `default` |
| `redirect_out` | `pipe` |


|  Command Struct 2 Var  | Value |
|-------------|------------|
| `commmand_name` | `grep` |
| `argv_array` | `grep`, `SHELL`,  NULL |
| `envp_array` | `NULL` |
| `redirect_in` | `pipe` |
| `redirect_out` | `output.txt` |

### 4. Command Execution
1: Create a common envp array containing all shell environment variables.

2: Loop through the command execution process:

- create pipe as needed for redirection

- Fork child process.

#### Child Process

1: **Changes the pgid** to pgid of entire group.

2: **Reads the command structure** to retrieve the command name, arguments, environment variables, and redirection information.

3: **Open src/dst files**: depending on the redirect in/out soecified inside command struct, it opens the file.

4: **Applies I/O redirections**: Used `dup2()` to redirect standard input or standard output as specified by the command.

5: **Populates the environment array** with the shell's environment variables.

6: **Waits for a signal** from **Parent**

7: **Checks for built-in commands** to determine whether the command can be handled internally by the shell.

8: Decides and **Searches for the executable** by checking the directories listed in the **`$PATH` environment variable**.

9: Adds the **`_=`** environment variable to the common/specific environment array, setting its value to the command's executable path (`_=command_path`). (If the user hasn't added any temporary environment variables that need to be injected, I reuse the common envp array constructed in step 1 of command execution)

10: **Executes the command**: use `execve` to execute the command then handles error.

Final command structs before execution for command :

```bash
foo=bar env | grep SHELL > output.txt
```

|  Command Struct 1 Var  | Value |
|-------------|------------|
| `commmand_name` | `/bin/env` |
| `argv_array` | `env, NULL` |
| `envp_array` | `foo=bar`, *ALL_SHELL_ENV_VARS*, ` _=/bin/env, NULL` |
| `redirect_in` | `default` |
| `redirect_out` | `pipe` |


|  Command Struct 2 Var  | Value |
|-------------|------------|
| `commmand_name` | `/bin/grep` |
| `argv_array` | `grep`, `SHELL`, NULL |
| `envp_array` | *ALL_SHELL_ENV_VARS*, `_=/bin/grep, NULL` |
| `redirect_in` | `pipe` |
| `redirect_out` | `output.txt` |

#### Parent Process

1: **Loops** and creates all child processes.

2: **Puts child Pgid** into **foreground**

3: **Give signal** to child processes to start execution.

4: **Wait and reap** all child processes

5: **Put Shell** back into **foreground**




### Comparing to bash: Differences

-  **Multiple redirections**

  ```bash
  ls > output1.txt > output2.txt
  ```
  
  **BASH behaviour:**
  Both files are created. But the output is redirected to `output2.txt`.

  **MyShell behaviour:**
  Only `output2.txt` is created. And the output is redirected to `output2.txt`.

-  **Alias**: Aliases are not supported yet

-  **Shell variables**: Shell variables are not supported yet.

-  **Background jobs**: Using `&` to run commands in the background is not supported.

-  **&& operator**: Running a command only if the previous one succeeds is not supported.

-  **Limited expansion**: metacharacters [eg: `*`, `?ab.*`] are not expanded and simply treated as normal chars right now.

-  **source bic command**:  this shell doesn't parse Bash syntax like if, fi, etc.

-  **Limited Autocompletion**:  as I can't implement suggestions for options specific to individual commands.

-  **UTF-8 characters**: only ASCII characters are supported, so UTF-8 characters won't work properly.

-  And there are many more limitations that I can't list here. There's still plenty of room for improvement!


---
The goal of this project is to understand how a shell works internally by designing and implementing one from scratch. This shell is written entirely in x86-64 assembly, without relying on the C standard library. This is a deliberate choice i made, so i an get an idea of low-level system programming and become more familiar with Linux system calls.
