#!/bin/bash

# Simple wrapper script to run the CSV processor
# Usage: ./process.sh

cd "$(dirname "$0")"
npm run process
