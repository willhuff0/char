@echo off
cd /D "%~dp0"
firebase emulators:start --import emu_data --export-on-exit --only storage,functions,firestore,auth,ui