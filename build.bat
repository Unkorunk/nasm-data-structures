@echo off
nasm -f win64 -o heap.obj heap.asm
link heap.obj /NOENTRY /OUT:heap.dll /EXPORT:heap_create /EXPORT:heap_destroy /EXPORT:heap_reserve /EXPORT:heap_build /EXPORT:heap_push /EXPORT:heap_pop /EXPORT:heap_top /EXPORT:heap_capacity /EXPORT:heap_size /EXPORT:heap_empty /DLL kernel32.lib