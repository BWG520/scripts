#!/bin/bash
cat /dev/random|tr -dc '0-9a-zA-z'|head -c $1|xargs
