#!/bin/bash

echo $(pwd)
echo "This script does fetch --prune on all repositories"

fetch() {
  local dir=$1
  pushd "$dir" > /dev/null
  if [ -d "./.git" ] ; then
    echo "Fetch on $dir"
    git fetch --prune
  fi
  popd > /dev/null
}

shopt -s dotglob
find * -prune -type d | while IFS= read -r dir; do
  fetch $dir
done

