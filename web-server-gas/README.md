# web-server-gas

A tiny HTTP/1.0 server written in x86-64 GAS assembly (Intel syntax) for
Linux. Talks directly to the kernel via syscalls — no libc.

For each accepted connection it `fork()`s a child handler that:

- **GET `/path`** — opens `path` (relative to the cwd), reads up to 1024
  bytes, and writes them back after a `200 OK`.
- **POST `/path`** — creates/truncates `path` and writes the request body
  (everything after the `\r\n\r\n` header terminator) into it, then replies
  `200 OK`.

This is a learning exercise, not a production server: no error handling, no
chunking past 1KB, no path sanitization, no `Content-Length`, etc.

## Requirements

- Linux x86_64
- GNU `as` and `ld` (binutils)

## Build & run

```
make
sudo ./server      # binds to port 80, hence sudo
# or:
sudo make run
make clean
```

The listening port is hardcoded as `PORT_BIG_ENDI = 0x5000` (port 80 in
network byte order) at the top of `server.s` — edit and rebuild to change
it. Picking a port above 1024 lets you skip `sudo`.

## Quick test

```
echo "hello" > index.html
sudo ./server &
curl http://localhost/index.html
curl -X POST --data-binary "world" http://localhost/out.txt
cat out.txt
```
