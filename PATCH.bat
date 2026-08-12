@echo off
echo f | xcopy /y "smw.sfc" "patched.sfc"
asar patch.asm patched.sfc
