#!/bin/bash

STARTUP=`date +%s`
sleep 10
SHUTDOWN=`date +%s`
expr $STARTUP - $SHUTDOWN
