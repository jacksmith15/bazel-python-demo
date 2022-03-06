#!/usr/bin/env bash

black src && isort src || exit 1
