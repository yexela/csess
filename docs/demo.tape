# csess demo tape — render with:  vhs docs/demo.tape
# Requires: vhs (brew install vhs), a running csess DB seeded with docs/demo-seed.sql
# into a `sessions_demo` database, and csess on PATH. Produces docs/demo.gif

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

# --- fuzzy find: the star ---
Type "# find any past session by content, tag, or fuzzy match"
Sleep 800ms
Enter
Type "csess find"
Sleep 400ms
Enter
Sleep 1500ms
Type "stripe"
Sleep 2500ms
Escape
Sleep 900ms

# --- the menu: no commands to memorize ---
Type "# forgot the commands? just run 'csess'"
Sleep 800ms
Enter
Type "csess"
Sleep 400ms
Enter
Sleep 3200ms
Escape
Sleep 1000ms
