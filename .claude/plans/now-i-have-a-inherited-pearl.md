# Context

Retheme ~/.p10k.zsh to Tokyo Night. The user provided their exact terminal color palette (Alacritty/Kitty config), so we use ANSI colors 0–15 directly — they render as the exact Tokyo Night hex values defined in the terminal. No 256-color approximations needed for semantic colors.

## Terminal color reference

| Index | Role       | Hex       |
|-------|------------|-----------|
| 0     | black      | #15161e   |
| 1     | red        | #f7768e   |
| 2     | green      | #9ece6a   |
| 3     | yellow     | #e0af68   |
| 4     | blue       | #7aa2f7   |
| 5     | magenta    | #bb9af7   |
| 6     | cyan       | #7dcfff   |
| 7     | white      | #a9b1d6   |
| 8     | br.black   | #414868   |
| 9     | br.red     | #ff899d   |
| 10    | br.green   | #9fe044   |
| 11    | br.yellow  | #faba4a   |
| 12    | br.blue    | #8db0ff   |
| 13    | br.magenta | #c7a9ff   |
| 14    | br.cyan    | #a4daff   |
| 15    | br.white   | #c0caf5   |

For segment background, use 235 (xterm-256 ≈ #262626), close to TN bg #1a1b26 since background isn't one of the 16 named colors.

## Semantic color rules

| Meaning              | Color index |
|----------------------|-------------|
| Clean / OK / success | 2 (green)   |
| Modified / warning   | 3 (yellow)  |
| Error / conflict     | 1 (red)     |
| Untracked / info     | 4 (blue)    |
| Directory path       | 4 (blue)    |
| Directory anchor     | 6 (cyan)    |
| Dim / meta / comment | 8 (br.black)|
| Foreground text      | 15 (br.white)|
| Purple accent        | 5 (magenta) |
| Teal (Python, Go)    | 6 (cyan)    |
| Orange-ish (Rust, AWS)| 11 (br.yellow #faba4a, closest to orange) |

## Complete change list

File: `/home/andreas/.p10k.zsh`

### Global / structural

| Line | Parameter | Old | New |
|------|-----------|-----|-----|
| 157  | `POWERLEVEL9K_MULTILINE_FIRST_PROMPT_GAP_FOREGROUND` | 242 | 8 |
| 165  | `POWERLEVEL9K_BACKGROUND` | 238 | 235 |
| 139-145 | multiline prefix/suffix strings — replace embedded `%242F` | 242 | 8 |
| 168  | LEFT_SUBSEGMENT_SEPARATOR string — replace `%246F` | 246 | 8 |
| 170  | RIGHT_SUBSEGMENT_SEPARATOR string — replace `%246F` | 246 | 8 |

### os_icon
| 191 | `POWERLEVEL9K_OS_ICON_FOREGROUND` | 255 | 15 |

### prompt_char
| 199 | `POWERLEVEL9K_PROMPT_CHAR_OK_*_FOREGROUND` | 76 | 2 |
| 201 | `POWERLEVEL9K_PROMPT_CHAR_ERROR_*_FOREGROUND` | 196 | 1 |

### dir
| 220 | `POWERLEVEL9K_DIR_FOREGROUND` | 31 | 4 |
| 227 | `POWERLEVEL9K_DIR_SHORTENED_FOREGROUND` | 103 | 8 |
| 230 | `POWERLEVEL9K_DIR_ANCHOR_FOREGROUND` | 39 | 6 |

### vcs formatter function (my_git_formatter, lines 383–394)

These are local variables inside the function body with inline `%NF` codes.

| Line | Variable | Old | New |
|------|----------|-----|-----|
| 383  | `meta` (clean state) | `%248F` | `%8F` |
| 384  | `clean` | `%76F` | `%2F` |
| 385  | `modified` | `%178F` | `%3F` |
| 386  | `untracked` | `%39F` | `%4F` |
| 387  | `conflicted` | `%196F` | `%1F` |
| 390–394 | all 5 stale variables | `%244F` | `%8F` |

### vcs segment
| 500 | `POWERLEVEL9K_VCS_VISUAL_IDENTIFIER_COLOR` | 76 | 2 |
| 501 | `POWERLEVEL9K_VCS_LOADING_VISUAL_IDENTIFIER_COLOR` | 244 | 8 |
| 514 | `POWERLEVEL9K_VCS_CLEAN_FOREGROUND` | 76 | 2 |
| 515 | `POWERLEVEL9K_VCS_UNTRACKED_FOREGROUND` | 76 | 4 |
| 516 | `POWERLEVEL9K_VCS_MODIFIED_FOREGROUND` | 178 | 3 |

### status
| 526 | `POWERLEVEL9K_STATUS_OK_FOREGROUND` | 70 | 2 |
| 532 | `POWERLEVEL9K_STATUS_OK_PIPE_FOREGROUND` | 70 | 2 |
| 538 | `POWERLEVEL9K_STATUS_ERROR_FOREGROUND` | 160 | 1 |
| 543 | `POWERLEVEL9K_STATUS_ERROR_SIGNAL_FOREGROUND` | 160 | 1 |
| 551 | `POWERLEVEL9K_STATUS_ERROR_PIPE_FOREGROUND` | 160 | 1 |

### command_execution_time
| 560 | `POWERLEVEL9K_COMMAND_EXECUTION_TIME_FOREGROUND` | 248 | 8 |

### background_jobs
| 572 | `POWERLEVEL9K_BACKGROUND_JOBS_FOREGROUND` | 37 | 6 |

### direnv
| 578 | `POWERLEVEL9K_DIRENV_FOREGROUND` | 178 | 3 |

### vi_mode
| 808 | `POWERLEVEL9K_VI_MODE_NORMAL_FOREGROUND` | 106 | 2 |
| 811 | `POWERLEVEL9K_VI_MODE_VISUAL_FOREGROUND` | 68 | 4 |
| 814 | `POWERLEVEL9K_VI_MODE_OVERWRITE_FOREGROUND` | 172 | 11 |
| 817 | `POWERLEVEL9K_VI_MODE_INSERT_FOREGROUND` | 66 | 6 |

### context
| 927 | `POWERLEVEL9K_CONTEXT_ROOT_FOREGROUND` | 178 | 1 |
| 929 | `POWERLEVEL9K_CONTEXT_{REMOTE,REMOTE_SUDO}_FOREGROUND` | 180 | 3 |
| 931 | `POWERLEVEL9K_CONTEXT_FOREGROUND` | 180 | 7 |

### asdf / version managers
| 585  | `POWERLEVEL9K_ASDF_FOREGROUND` (default) | 66 | 8 |
| 643  | `POWERLEVEL9K_ASDF_RUBY_FOREGROUND` | 168 | 1 |
| 648  | `POWERLEVEL9K_ASDF_PYTHON_FOREGROUND` | 37 | 6 |
| 653  | `POWERLEVEL9K_ASDF_GOLANG_FOREGROUND` | 37 | 6 |
| 658  | `POWERLEVEL9K_ASDF_NODEJS_FOREGROUND` | 70 | 2 |
| 663  | `POWERLEVEL9K_ASDF_RUST_FOREGROUND` | 37 | 11 |
| 668  | `POWERLEVEL9K_ASDF_DOTNET_CORE_FOREGROUND` | 134 | 5 |
| 673  | `POWERLEVEL9K_ASDF_FLUTTER_FOREGROUND` | 38 | 6 |
| 678  | `POWERLEVEL9K_ASDF_LUA_FOREGROUND` | 32 | 4 |
| 683  | `POWERLEVEL9K_ASDF_JAVA_FOREGROUND` | 32 | 11 |
| 688  | `POWERLEVEL9K_ASDF_PERL_FOREGROUND` | 67 | 8 |
| 693  | `POWERLEVEL9K_ASDF_ERLANG_FOREGROUND` | 125 | 1 |
| 698  | `POWERLEVEL9K_ASDF_ELIXIR_FOREGROUND` | 129 | 5 |
| 703  | `POWERLEVEL9K_ASDF_POSTGRES_FOREGROUND` | 31 | 4 |
| 708  | `POWERLEVEL9K_ASDF_PHP_FOREGROUND` | 99 | 5 |
| 713  | `POWERLEVEL9K_ASDF_HASKELL_FOREGROUND` | 172 | 5 |
| 718  | `POWERLEVEL9K_ASDF_JULIA_FOREGROUND` | 70 | 5 |

### standalone version managers
| 951  | `POWERLEVEL9K_VIRTUALENV_FOREGROUND` | 37 | 6 |
| 964  | `POWERLEVEL9K_ANACONDA_FOREGROUND` | 37 | 6 |
| 997  | `POWERLEVEL9K_PYENV_FOREGROUND` | 37 | 6 |
| 1023 | `POWERLEVEL9K_GOENV_FOREGROUND` | 37 | 6 |
| 1036 | `POWERLEVEL9K_NODENV_FOREGROUND` | 70 | 2 |
| 1049 | `POWERLEVEL9K_NVM_FOREGROUND` | 70 | 2 |
| 1060 | `POWERLEVEL9K_NODEENV_FOREGROUND` | 70 | 2 |
| 1070 | `POWERLEVEL9K_NODE_VERSION_FOREGROUND` | 70 | 2 |
| 1078 | `POWERLEVEL9K_GO_VERSION_FOREGROUND` | 37 | 6 |
| 1086 | `POWERLEVEL9K_RUST_VERSION_FOREGROUND` | 37 | 11 |
| 1167 | `POWERLEVEL9K_LUAENV_FOREGROUND` | 32 | 4 |

### cloud / infra
| 1284 | `POWERLEVEL9K_TERRAFORM_OTHER_FOREGROUND` | 38 | 5 |
| 1289 | `POWERLEVEL9K_TERRAFORM_VERSION_FOREGROUND` | 38 | 5 |
| 1328 | `POWERLEVEL9K_KUBECONTEXT_DEFAULT_FOREGROUND` | 134 | 4 |
| 1412 | `POWERLEVEL9K_AWS_DEFAULT_FOREGROUND` | 208 | 11 |
| 1423 | `POWERLEVEL9K_AWS_EB_ENV_FOREGROUND` | 70 | 2 |

## Implementation approach

Three edit categories:
- **A — bare numbers**: `typeset -g PARAM=NNN` lines — simple number replacement, target by param name
- **B — embedded `%NF` in string literals**: lines 139-145 (`%242F` → `%8F`) and 168/170 (`%246F` → `%8F`) — must edit the surrounding string context to be unambiguous
- **C — `my_git_formatter` function body** (lines 383-394): local variable assignments with inline `%NF` codes — target by variable name + line

Process edits from bottom of file to top to avoid line-number drift.

## Verification

Run `source ~/.p10k.zsh` in a terminal, then verify:
1. `cd` into a git repo — check branch color (green = clean, yellow = modified, red = conflict)
2. Run a failing command — check red exit status indicator
3. Run a slow command (`sleep 3`) — check dim execution time color
4. Check the directory path colors (blue path, cyan anchor segment)
