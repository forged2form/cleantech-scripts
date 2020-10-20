#!/bin/bash

### Functions pertaining to keeping track of progress and restarting in the event of a crash. ###

### in_stage $VAR

if [ ! -d /home/"$(whoami)/.fahtdiag" ]; then
	mkdir /home/"$(whoami)/.fahtdiag"
fi

curr_stage () {
        
}  