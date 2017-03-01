#!/bin/bash
# sync_git_all.sh

# Enabled strict mode"
set -euo pipefail
IFS=$'\n\t'

set -m # Enable Job Control

echo "This script does a FETCH and a PULL of develop branch"

declare -i -r MAX_PROCESSES=4
# TODO FOREACH BRANCH in BRANCHES
#declare -r -a BRANCHES=( "develop" "release" "master" )

## $1 -> Directory to process
function process_directories_git() {
  # Avoid freezing the computer with too many processes
  while [[ $(jobs | wc -l) -ge MAX_PROCESSES ]] ; do sleep 1 ; done
  local DIR=$1
  local -i ERROR_CODE=0;

  DIR=${DIR#"./"}
  #echo "$(pwd)->cd $DIR";
  cd $DIR

  if [ ! -f ".git/config" ]; then
    #It isn't a git repot, check childrens
    local DIRS=$(find "." -maxdepth 1 -type d -not -name ".*" -not -path '*/\.*' );
    #echo ":${DIRS}"
    for SDIR in $DIRS ; do
      process_directories_git $SDIR &
    done
    # Wait for all parallel jobs to finish
    while [ 1 ]; do 
      fg 2> /dev/null; 
      [ $? == 1 ] && break; 
    done
      ##ERROR_CODE=$?
      ##if [ $ERROR_CODE -ne 0 ]; then
      ##  echo -e "### \033[31mError processing ${SDIR}."
      ##  return $ERROR_CODE
      ##fi
  else
    echo "Procesing $(pwd)";
    process_git_repo;
    ERROR_CODE=$?
  fi
  cd ..
  return $ERROR_CODE ;
}

## Process the git reposiory on the actual work directory
function process_git_repo() {
  local -i ERROR_CODE=0;

  local ACTUAL_BRANCH=$(git symbolic-ref --short HEAD) # Stores actual branch
  echo "Actual branch ${ACTUAL_BRANCH}"

  # Update local repository from remote
  git fetch
  ERROR_CODE=$?
  if [ $ERROR_CODE -ne 0 ]; then
    echo -e "### \033[31mError doing a git fetch!\e[0m."
    return $ERROR_CODE;
  fi

  # if there is any local change, stash it
  local LOCALCHANGES=$(git status --porcelain | grep -v "??")
  if [ -n "${LOCALCHANGES}" ]; then
    git stash save "temporal stash before doing pull"
    ERROR_CODE=$?
    if [ $ERROR_CODE -ne 0 ]; then
      echo -e "### \033[31mError doing a git stash\e[0m."
      return $ERROR_CODE;
    fi
  fi

  # Go to develop branch
  BRANCH="develop"
  if [ "${ACTUAL_BRANCH}" != "${BRANCH}" ]; then
    if [ "$(git branch | grep "${BRANCH}")" != "" ]; then
      git checkout develop
      ERROR_CODE=$?
      if [ ! $ERROR_CODE -eq 0 ]; then
        echo -e "### \033[31mError doing a git checkout to develop branch\e[0m."
        return $ERROR_CODE;
      fi
    else
      echo -e "### \033[31mThere isn't a branch called ${BRANCH}\e[0m."
      return 0;
    fi

  fi

  if [ $ERROR_CODE -eq 0 ]; then
    git pull
    ERROR_CODE=$?
    if [ $ERROR_CODE -ne 0 ]; then
      echo -e "### \033[31mError doing a git pull on develop branch\e[0m Check develop branch."
      return $ERROR_CODE;
    fi
  fi

  # Get back to the original branch
  local BRANCH=$(git symbolic-ref --short HEAD)
  if [ "$BRANCH" == "$ACTUAL_BRANCH" ]; then
    git checkout $ACTUAL_BRANCH
    if [ $ERROR_CODE -ne 0 ]; then
      echo -e "### \033[31mError doing a git checkout to ${ACTUAL_BRANCH} branch\e[0m"
      return $ERROR_CODE;
    fi
  fi

  # Restore local changes
  if [ -n "${LOCALCHANGES}" ]; then
    stash_pop ;
  fi

  echo " "
  return $ERROR_CODE;
}

function stash_pop() {
  echo "Restauring local changes"
  git stash pop
  if [ $? -ne 0 ]; then
    echo -e "### \033[31mError doing a git stash pop\e[0m"
  fi
  return 0;
}

if [ -z "$1" ]; then
  echo "Error: This script expect a path to git reposiories as parameter."
  exit 1
fi

WORKDIR=`pwd`
PDIR=$1

# Preparacion de la ruta base
if [ ! "${PDIR:0:1}" == "/" ]; then
  PDIR="./${PDIR}"
fi
if [ ! "${PDIR: -1}" == "/" ]; then
  PDIR="${PDIR}/"
fi
echo "Start on ${PDIR}"
process_directories_git $PDIR ;
cd $WORKDIR

