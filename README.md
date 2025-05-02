
## PS5 Lua Loader

Fork of [remote_lua_loader](https://github.com/shahrilnet/remote_lua_loader)

Automatically loads UMTX, ELF Loader, and your ELF payloads.
Supports PS5 firmware up to 7.61.

## How to use
* Create a directory named `ps5_lua_loader`.
* Inside this directory, place your ELF payloads and an `autoload.txt` file.
    * In `autoload.txt`, list the ELF filenames you want to load (one per line).  
      Filenames are case-sensitive - make sure the names exactly match your ELF files.
    * You can add lines like `!1000` to make the loader wait 1000ms before sending the next payload.
* Put the `ps5_lua_loader` directory in one of these locations:
    * In the root of a USB drive
    * In the internal drive at `/data/ps5_lua_loader`
    * In the game’s savedata folder
* Import savedata to your game:  
  Follow the steps in [SETUP.md](SETUP.md) to prepare and import the savedata for your Lua-compatible game.
   

## Game Compatibility

Currently this loader is compatible with the following games:
  
| Game Title                            | CUSA ID     | Notes                                                                           |
|---------------------------------------|-------------|---------------------------------------------------------------------------------|
| Raspberry Cube                        | CUSA16074   |                                                                                 |
| Aibeya                                | CUSA17068   |                                                                                 |
| Hamidashi Creative                    | CUSA27389   |                                                                                 |
| Hamidashi Creative Demo               | CUSA27390   | Requires latest firmware to download from PSN                                   |
| Aikagi Kimi to Issho ni Pack          | CUSA16229   |                                                                                 |
| Aikagi 2                              | CUSA19556   |                                                                                 |
| IxSHE Tell                            | CUSA17112   |                                                                                 |
| Nora Princess and Stray Cat Heart HD  | CUSA13303   | Requires manual loading of savegame (rename `save9999.dat` to `nora_01.dat`)    |

## Credits

* shahrilnet – creator and maintainer of the original [remote_lua_loader](https://github.com/shahrilnet/remote_lua_loader)
* excellent blog [post](https://memorycorruption.net/posts/rce-lua-factorio/) where most of the ideas of lua primitives are taken from 
* flatz - for sharing ideas and lua implementations
* null_ptr - for helping to develop umtx exploit for PS5 & numerous helps with the loader development
* gezine - for sharing the vulnerable games & ideas
* specter & chendo - for webkit implementations which i refer a lot
* al-azif - parts and information grabbed from his sdk, aswell as from his ftp server
* horror - for the notification popup and ftp server payloads
* everyone else who shared their knowledge with the community

