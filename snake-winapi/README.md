# snake-winapi

Classic Snake for the Windows console, written in x86-64 MASM assembly. Uses
the Win32 console API (`WriteConsoleOutputW`, `GetAsyncKeyState`, `Sleep`)
to render a 200x28 board of UTF-16 characters and read arrow-key input.

## Controls

- Arrow keys: change direction
- Game ends when the snake collides with itself or a wall

## Requirements

- Windows
- MASM (`ml64`) and the Microsoft linker (`link`) — installed with Visual
  Studio's "Desktop development with C++" workload

## Build & run

From a **x64 Native Tools Command Prompt for VS** (so `ml64` and `link` are
on `PATH`):

```
nmake          # or: make
nmake run      # build, then launch the game
nmake clean
```

Alternatively, run the bundled `run_winapi_snake.bat` from any shell — it
calls `vcvarsall.bat` itself before assembling, linking, and launching.

## Files

- `winapi_snake.asm` — source
- `run_winapi_snake.bat` — one-shot build+run script that sets up the VS env
- `Makefile` — assumes the VS env is already set up
