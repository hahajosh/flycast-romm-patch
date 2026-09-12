# flycast-romm-patch

Hello! This is a personal project I made to add flycast to a release RomM build. 
I accomplished this by injecting the minimum required code to register the dreamcast as a playable console, and to make the flycast-wasm work. This works via docker-compose on the romm:latest image. 

*Setup Instructions*
1. Copy the contents of this repo into a romm docker volume
    this is what I did: - ./dev:/romm/dev
    where ./dev also has a flycast subdirectory
2. update your docker compose to include this command
    command: >
      sh -c "
        chmod +x /romm/dev/flycast/patch-flycast.sh &&
        /romm/dev/flycast/patch-flycast.sh
        exec /init
      "

      this will call the custom patching script, and also the standard /init
3. ensure you have uploaded your dreamcast bios
4. start playing games!

*What does the script do?*
patch-flycast.sh does the following:
1. Updates the generated index.js file that comes from index.ts. I have this weird workaround that hopefully keeps working. It generates with an obfuscated name it seems, but the structure is consistently index-*.js. This will add dc and flycast to the _EJS_CORES_MAP, which will register the game as playable and link to the flycast-wasm.data

2. Overrides the base WebGL logic with custom js functions. It wasn't running without this patch. This is injected into the loader.js emulatorjs code, and only runs when the core is flycast

3. Next, it copies the flycast-data.wasm file to the correct EmulatorJS cores location

4. Finally, it copies the flycast.json to the reports section for EmulatorJS cores


*Notes*
- I can't promise this works for other setups, and I don't even think this is the best approach. I just wanted to make dreamcast games work in RomM without having to run a dev build, or waiting for the EmulatorJS and RomM projects to add it.
- I had to modify the flycast-wasm js module to not abort on missing functions. For some reason I couldn't figure out, it calls these zip functions that aren't present. This could probably be fixed in the future if I figure out how to build the wasm myself
- I can only get stable 60 fps on Brave browser. I've tested on Safari, Firefox, and Chrome and they ran at 40 fps max with all sorts of audio glitches
- I did not add a legacy wasm since those are for WebGL turned off I believe, and fycsat requires WebGL is my understanding...
- this is coded all via macos, and has not been tested on any other OS. It should also work on linux...
- The patch-flycast.sh script is pretty much all AI generated. You should give all this code a look over before running in your environment of course. 

It is based on these two repos:
- https://github.com/rommapp/romm
- https://github.com/nasomers/flycast-wasm

