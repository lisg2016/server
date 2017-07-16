#!/bin/sh

ulimit -c unlimited
ulimit -n 10240

../skynet/skynet ./etc/config.agent11
