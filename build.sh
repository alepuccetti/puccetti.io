#!/usr/bin/env bash

hugo --cleanDestinationDir --destination docs/

# Restore the CNAME file for GitHub Pages
git checkout -- docs/CNAME
