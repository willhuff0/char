#!/bin/bash
cd "$(dirname "$0")"
firebase emulators:start --import emu_data --export-on-exit --only storage,functions,firestore,auth,ui