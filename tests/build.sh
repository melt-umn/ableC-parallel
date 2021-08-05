#!/bin/bash
export SVJVM_FLAGS=${SVJVM_FLAGS:-"-Xmx5000M -Xss20M"}
silver-ableC $@
