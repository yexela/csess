# csess demo tape — render with:  vhs docs/demo.tape
# Requires: vhs (brew install vhs), a running csess DB, and csess on PATH.
# Produces docs/demo.gif

Output docs/demo.gif

Set Shell "bash"
Set FontSize 18
Set Width 1200
Set Height 720
Set Padding 20
Set Theme "Catppuccin Mocha"
Set TypingSpeed 55ms

# --- setup (hidden from the recording) ---
Hide
Type "export PATH=$HOME/.local/bin:$PATH" Enter
Type "export CSESS_DB=sessions_demo" Enter
Type "clear" Enter
Show

# --- browse with AI titles + tags ---
Type "# browse your Claude Code sessions — with AI titles and tags"
Sleep 800ms
Enter
Type "csess list"
Sleep 400ms
Enter
Sleep 3s

# --- full-content search ---
Type "# search the full text of every conversation, not just the first line"
Sleep 800ms
Enter
Type "csess search testflight"
Sleep 400ms
Enter
Sleep 3s

# --- interactive fuzzy picker ---
Type "# fuzzy-find with live preview  (Enter would resume it in this folder)"
Sleep 800ms
Enter
Type "csess find"
Sleep 400ms
Enter
Sleep 1500ms
Type "stripe"
Sleep 2500ms
Escape
Sleep 1200ms
