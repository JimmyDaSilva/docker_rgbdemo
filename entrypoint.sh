#!/bin/bash
set -e

# start in home directory 
cd 

# run rgbdemo
exec bash -i -c /home/docker/rgbdemo/build/bin/rgbd-scan-markers

exec bash
