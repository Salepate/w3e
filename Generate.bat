del /F /Q "amalg.cache"
set LUA_PATH=lua\\?.lua;amalg\\?.lua;
lua54.exe -lamalg lua/game.lua
lua54.exe amalg/amalg.lua -s lua/game.lua -o output/war3_code.lua -c