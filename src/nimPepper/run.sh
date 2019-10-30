#!/bin/sh
nim c --os:windows installation.nim
cp installation.exe /home/david/vmshare/
vboxmanage guestcontrol windows7 run --username peter --password 123poipoi --exe "Z:/installation.exe" --wait-stdout
