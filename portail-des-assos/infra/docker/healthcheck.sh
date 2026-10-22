#!/bin/sh
if curl -s --fail http://localhost:8005 > /dev/null; then
    exit 0
else
    exit 1
fi
