#!/bin/bash

echo "This script removes all 'target' directories"

deleteTarget() {
  local dir=$1
  pushd "$dir" > /dev/null
  if [ -d "target" ]; then
    echo "Removing target on $dir"
    rm -rf target
  fi
  popd > /dev/null
}

deleteTargetSubDir() {
  local dir=$1
  deleteTarget $dir
  pushd "$dir" > /dev/null
  find * -prune -type d | while IFS= read -r subdir; do 
    deleteTarget $subdir
  done
  popd > /dev/null
}
shopt -s dotglob
find * -prune -type d | while IFS= read -r dir; do 
  deleteTargetSubDir $dir
done

