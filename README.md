# asm-collection

A small collection of x86-64 assembly programs, each self-contained in its
own subdirectory with a `Makefile` and `README.md`.

| Project | Platform | Assembler | Description |
| --- | --- | --- | --- |
| [`snake-winapi`](./snake-winapi) | Windows | MASM (`ml64`) | Snake game in the Windows console using the Win32 API |
| [`web-server-gas`](./web-server-gas) | Linux | GAS (`as`) | HTTP/1.0 server using raw Linux syscalls — supports GET (read file) and POST (write file) |

Each project builds with `make` (or `nmake` on Windows) and runs with
`make run`. See the per-project README for prerequisites and details.
