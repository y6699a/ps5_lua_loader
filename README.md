
## Remote Lua Loader

Remote lua loader for PS4 and PS5, based on gezine's [finding](https://github.com/Gezine/ArtemisLuaLoader/) that allows games built with Artemis engine to load arbitrary lua file. Currently this loader is specific for Raspberry Cube (CUSA16074). The loader is not firmware dependant, and has been successfully tested on PS5 Pro 10.20.

### Usage on jailbroken PS4 with disc version

1. Play the game for a while until you can create save data
2. Use Apollo Save Tool to export decrypted save data to USB drive
3. Copy and paste all files from savedata into USB drive (x:\PS4\APOLLO\id_CUSA16074_savedata), overwriting currently existing save data
4. Make sure that `PLATFORM` variable on top of inject.lua is set appropriately
5. Use Apollo Save Tool to import the new save data from USB drive
6. Run the game and check if there is a popup from lua loader
7. Use send_lua.py to send lua file to the loader

If you have a jailbroken PS5 with a non activated account, you can use OffAct from https://github.com/ps5-payload-dev/websrv/releases to offline activate the account and transfer save data with matching account ID using FTP.

## Credits

* flatz - for sharing ideas and lua implementations
* null_ptr - for testing & ideas
* gezine - for sharing the vulnerable games & ideas
* specter & chendo - for webkit implementations which i refer a lot
* everyone else who shared their knowledge with the community

