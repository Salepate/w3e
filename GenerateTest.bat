del /F /Q "amalg.cache"
set LUA_PATH=lua\\?.lua;amalg\\?.lua;
lua54.exe -lamalg lua/test.lua
lua54.exe amalg/amalg.lua -s lua/test.lua -o output/war3_test.lua -c