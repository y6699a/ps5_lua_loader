
Use `send_lua.py` to communicate with the loader

Examples: `$ python send_lua.py 192.168.1.2 9026 hello_world.lua`

### Payloads

1. `hello_world.lua` - Prints basic information back from the game process - its process id, the base of the eboot, libc and libkernel.
2. `ftp_server.lua` - Runs an FTP server on port 1337 that allows browsing the filesystem as seen by the game process, and also upload and download files. If the game process is jailbroken, it can view more files on the filesystem. 

### Payloads after jailbroken game process

1. `kdata_dumper.lua` - Dump content of kernel .data segments over network (NOTE: you must modify the IP address before you run this payload)
2. `read_klog.lua` - Read content of `/dev/klog` to user.
3. `elf_loader.lua` - Load ELF binary from file system (by default it will load `/data/elfldr.elf`). Use FTP server to place the ELF file.

### send_lua.py additional commands

* `--disable-thread` - Disables the option to run payloads in a new thread.
* `--enable-thread` - Enables the option to run payloads in a new thread.
* `--enable-signal-handler` - Enables the option to catch signals (such as crash, etc).
* `--disable-signal-handler` - Disables the option to catch signals.