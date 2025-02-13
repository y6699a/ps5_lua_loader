
Use `send_lua.py` to communicate with the loader

Examples:
* `$ python send_lua.py <IP> 9026 hello_world.lua` - Run a simple payload
* `$ python send_lua.py <IP> 9026 --disable-signal-handler` - Disable signal handler on the loader

### Payloads

| Payload | Description |
| -------- | ------- |
| hello_world.lua | Prints basic information back from the game process - its process id, the base of the eboot, libc and libkernel. |
| ftp_server.lua | Runs an FTP server on port 1337 that allows browsing the filesystem as seen by the game process, and also upload and download files. If the game process is jailbroken, it can access more files / directories on the filesystem. |
| umtx.lua | Kernel exploit for PS5 (fw <= 7.61). Once done, it will jailbreak the game process as well as the PlayStation, allowing for more access to the system. |

### Payloads after jailbroken game process

| Payload | Description |
| -------- | ------- |
| kdata_dumper.lua | Dump content of kernel .data segments over network (NOTE: you must modify the IP address before you run this payload) |
| read_klog.lua | Read content of `/dev/klog`. |
| elf_loader.lua | Rudimentary ELF loader to load from file system (by default it will load from `/data/elfldr.elf`). Use FTP server after jailbreaking to place the ELF file there. |

### send_lua.py additional options

| Option | Description |
| -------- | ------- |
| --enable-signal-handler | Enables the option to catch signals (such as crash, etc) |
| --disable-signal-handler | Disables the option to catch signals. |
