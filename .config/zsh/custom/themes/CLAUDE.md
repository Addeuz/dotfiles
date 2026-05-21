# agnoster.zsh-theme (custom)

Custom fork of the oh-my-zsh agnoster theme, located at `$ZSH_CUSTOM/themes/agnoster.zsh-theme`
(`~/.config/zsh/custom/themes/agnoster.zsh-theme`). The upstream theme lives at `$ZSH/themes/agnoster.zsh-theme`
and should not be edited — changes go here.

Activated in `~/.zshrc` with `ZSH_THEME="agnoster"`. Oh-my-zsh prefers `$ZSH_CUSTOM` over `$ZSH` when
both exist, so this file takes precedence automatically.

## Left prompt (PROMPT)

Standard agnoster segments in order: `status → virtualenv → aws → terraform → context → dir → git → bzr → hg`

**Customisations vs upstream:**
- `prompt_context` — shows `ssh` segment only when `$SSH_CLIENT` or `$SSH_TTY` is set; nothing otherwise.
  Upstream showed `user@host` whenever the user differed from `$DEFAULT_USER`.

## Right prompt (RPROMPT)

Entirely custom. Segments left→right: `duration → gcloud → kubectl`

`ZLE_RPROMPT_INDENT=0` is set in `~/.zshrc` to remove zsh's default 1-char right margin.

### Segment drawing

**`rprompt_segment <bg> <fg> <text>`** — draws one right-prompt segment with a left-pointing powerline
arrow (``). Tracks `$CURRENT_RBG` to colour arrows between adjacent segments. Call
`rprompt_end` after the last segment to reset state.

### Context relevance system

A generic registry controls which context segments are visible. Register a context with:

```zsh
_context_register <name> <tools-ERE-regex> [indicator-files...]
```

State is read via `$_CONTEXT_SHOW[name]` (1 = show, 0 = hide).

**How visibility is decided** (in priority order):
1. **While typing** — `zle-line-pre-redraw` fires on every keypress; if `$BUFFER` matches the
   tools regex the segment appears immediately. Uses `zle reset-prompt` only when the state
   changes (not every keypress) to avoid performance issues.
2. **After running a command** — `preexec` captures the command; `precmd` checks it against the
   regex and sets the baseline `$_CONTEXT_SHOW_CMD[name]`.
3. **Directory** — `precmd` also checks whether any registered indicator files exist in `$PWD`.

**Hooks** — a single shared set handles all registered contexts:
- `_rprompt_preexec` — saves last command + starts duration timer
- `_rprompt_precmd` — updates context show states + calculates `$_CMD_DURATION`
- `_rprompt_zle_update` — registered via `add-zle-hook-widget zle-line-pre-redraw`; requires
  `zle -N _rprompt_zle_update` before `add-zle-hook-widget` to register it as a widget first.

**Registered contexts:**

| Name | Tools | Indicator files |
|------|-------|-----------------|
| `kubectl` | kubectl helm k9s kubens kubectx kustomize flux argocd istioctl kubeadm | Chart.yaml kustomization.yaml kustomization.yml |
| `gcloud` | gcloud gsutil bq | .gcloudignore app.yaml cloudbuild.yaml |

### Segments

**`prompt_duration`** — shows how long the last command took. Only appears when ≥5s.
Format: `󱎫 12s` / `󱎫 1m30s` / `󱎫 2h5m` (nerd font timer icon). Color-coded by duration tier.
Uses `zsh/datetime` (`$EPOCHREALTIME`). Raw seconds stored in `$_CMD_DURATION_SECS` for the
color decision; use `${elapsed%%.*}` to truncate float — `int()` requires `zsh/mathfunc` and is avoided.

**`prompt_kube`** — shows `⎈ <context>` when kubectl context is relevant.
Respects `$KUBE_PS1_ENABLED` (kubeoff/kubeon). Namespace display controlled by
`$KUBE_PS1_NS_ENABLE` (set to `false` in `~/.zshrc`).

**`prompt_gcloud`** — shows `☁ <project>` when gcloud context is relevant.
Reads project from `gcloud config get-value project` (local file read, no network call).

### Colors

All colors are Tokyo Night palette, matching the tmux datetime widget (`bg=#7aa2f7 fg=#2A2F41`).
The shared foreground `#2A2F41` is used across all segments — do NOT use variable references
like `$AGNOSTER_KUBE_FG` as a default value in `:=` assignments, they resolve unreliably at
theme load time. Hardcode `#2A2F41` directly.

| Variable | Default | Segment |
|----------|---------|---------|
| `AGNOSTER_KUBE_BG` | `#7aa2f7` | kubectl background |
| `AGNOSTER_KUBE_FG` | `#2A2F41` | kubectl foreground |
| `AGNOSTER_GCLOUD_BG` | `#9ece6a` | gcloud background |
| `AGNOSTER_GCLOUD_FG` | `#2A2F41` | gcloud foreground |
| `AGNOSTER_DURATION_FG` | `#2A2F41` | duration foreground (all tiers) |
| `AGNOSTER_DURATION_SHORT_BG` | `#9ece6a` | duration background < 30s (green) |
| `AGNOSTER_DURATION_MED_BG` | `#e0af68` | duration background 30s–2m (yellow) |
| `AGNOSTER_DURATION_LONG_BG` | `#f7768e` | duration background ≥ 2m (red) |

Override any of these in `~/.zshrc` before `source $ZSH/oh-my-zsh.sh`.

## Relevant ~/.zshrc settings

```zsh
ZSH_THEME="agnoster"
KUBE_PS1_NS_ENABLE=false   # hide namespace from kubectl segment
ZLE_RPROMPT_INDENT=0       # flush RPROMPT to right terminal edge
```

## Adding a new RPROMPT segment

1. Register it: `_context_register myname "tools-regex" indicator-file.yaml`
2. Write a renderer:
   ```zsh
   prompt_myname() {
     [[ ${_CONTEXT_SHOW[myname]} -eq 0 ]] && return
     rprompt_segment "$BG" "$FG" "icon text"
   }
   ```
3. Add `prompt_myname` to `build_rprompt` in the desired position.
