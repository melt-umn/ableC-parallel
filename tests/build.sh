#!/bin/bash
export SVJVM_FLAGS=${SVJVM_FLAGS:-"-Xmx6000M -Xss20M"}
silver-ableC $@
