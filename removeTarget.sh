#!/bin/bash

echo "This script removes all 'target' directories"

deleteMavenTargetSubDir() {
  local dir=$1
  pushd "$dir" > /dev/null
  if [ -f "pom.xml" ]; then
    echo "mvn clean on $dir"
    mvnd -q clean 2>/dev/null
  fi
  popd > /dev/null
}

shopt -s dotglob
find * -prune -type d | while IFS= read -r dir; do
  deleteMavenTargetSubDir $dir
done


