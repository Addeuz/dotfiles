# Plan: Add TMUX_INLINE env var to run.sh

## Context

When already inside a tmux session, `run.sh` creates a brand new `fg_session` and either switches to it (`tmux switch-client`) or attaches a nested tmux process (`tmux attach`). This causes tmux-inside-tmux. The request is to add an env var (`TMUX_INLINE`) that, when set, opens the foreground panes as a new window inside the *current* tmux session instead.

## File to modify

`tools/local/run.sh`

---

## Changes

### 1. fg_session / fg_window setup (around lines 60–65)

Replace:
```bash
fg_session=$(tmux new -s ${fg_session_name} -d -P -F ${session_format})

## Naming convention is row, col
fg_window=$(tmux list-windows -t ${fg_session} -F ${window_format})
fg_pane1=$(tmux list-panes -t ${fg_window} -F ${pane_format})
```

With:
```bash
if [[ -n "${TMUX_INLINE:-}" ]]; then
  fg_window=$(tmux new-window -n ${fg_session_name} -P -F ${window_format})
else
  fg_session=$(tmux new -s ${fg_session_name} -d -P -F ${session_format})
  fg_window=$(tmux list-windows -t ${fg_session} -F ${window_format})
fi

## Naming convention is row, col
fg_pane1=$(tmux list-panes -t ${fg_window} -F ${pane_format})
```

In inline mode `fg_session` is never set (it's only used in the `kill-session` and final `switch-client` calls, which are handled separately below).

### 2. Kill existing fg_session (line 33)

The `kill-session` line for `fg_session_name` is harmless to leave as-is — it will print an error and continue (`|| true`). No change needed.

### 3. Final attach/switch (line 124)

Replace:
```bash
tmux switch-client -t ${fg_session} || tmux -u -2 attach -t ${fg_session}
```

With:
```bash
if [[ -n "${TMUX_INLINE:-}" ]]; then
  tmux select-window -t ${fg_window}
else
  tmux switch-client -t ${fg_session} || tmux -u -2 attach -t ${fg_session}
fi
```

---

## Usage

```bash
TMUX_INLINE=1 tools/local/run.sh
```

Or export in `~/.zshrc` / a local override script to always use inline mode.

---

## Verification

1. Inside an existing tmux session, run `TMUX_INLINE=1 tools/local/run.sh`.
2. Confirm a new **window** (not a nested session) appears in the current tmux session containing all the service panes.
3. Without the variable, confirm original behaviour (new fg_session created, switch/attach as before).
