#!/bin/bash
export SVJVM_FLAGS=${SVJVM_FLAGS:-"-Xmx7000M -Xss30M"}
silver-ableC $@
