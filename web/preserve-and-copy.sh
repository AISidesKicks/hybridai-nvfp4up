#!/bin/bash

# if $NVFP4UP_ROOT is not set up, instruct to source ./nvfp4up_env_up.sh from project root

# Check if NVFP4UP_ROOT is set
if [ -z "$NVFP4UP_ROOT" ]; then
    echo "Error: NVFP4UP_ROOT environment variable is not set."
    echo "Please source the environment setup script from the project root:"
    echo "  source ./nvfp4up_env_up.sh"
    exit 1
fi

# Backup preserved file (CNAME)
echo "Backing up preserved file..."
cp $NVFP4UP_ROOT/docs/CNAME $NVFP4UP_ROOT/web/CNAME.bak 2>/dev/null || true

# Build the site
echo "Building site with VitePress..."
npx vitepress build src --outDir $NVFP4UP_ROOT/docs

# Restore preserved file
echo "Restoring preserved file..."
mv $NVFP4UP_ROOT/web/CNAME.bak $NVFP4UP_ROOT/docs/CNAME 2>/dev/null || true

# Cleanup backups if they weren't used (optional)
rm -f $NVFP4UP_ROOT/CNAME.bak

echo "Build complete!"