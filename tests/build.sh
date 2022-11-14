#!/bin/bash
export SVJVM_FLAGS=${SVJVM_FLAGS:-"-Xmx7000M -Xss20M"}
silver-ableC $@
