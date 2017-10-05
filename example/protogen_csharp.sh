#!/bin/bash

#set -o xtrace

# Generates protobuf C# datastructures from the proto directory.
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

PROTOBUF_DIR=${PROTOBUF_DIR-${DIR}/proto}
PROTOGEN_DIR=csharp-client/Model
GENERATION_DIR=${GENERATION_DIR-${DIR}/${PROTOGEN_DIR}}

# OS specific vars.
PROTOC_BIN=

# Builds all .proto files in a given package directory.
# NOTE: All .proto files in a given package must be processed *together*, otherwise the self-referencing
# between files in the same proto package will not work.
function proto_build_dir {
  DIR_FULL=${1}
  DIR_REL=${1##${PROTOBUF_DIR}}
  DIR_REL=${DIR_REL#/}
  echo -n "proto_build: $DIR_REL ..."
  mkdir -p ${GENERATION_DIR}/${DIR_REL} 2> /dev/null
  ${PROTOC_BIN}\
    --proto_path=${PROTOBUF_DIR} \
    --csharp_out "${GENERATION_DIR}/${DIR_REL}" \
    ${DIR_FULL}/*.proto || exit $?
  fix_output ${GENERATION_DIR}/${DIR_REL}
  echo "DONE"
}

function fix_output {
  DIR_FULL=${1}
  for file in $(ls ${DIR_FULL}/*.cs 2>/dev/null); do
    # This is a massive hack to remove validators which does not exists in C#.
    # ( This is because my proto uses go-validator package.
    sed --in-place='' "s/global::Validator.ValidatorReflection.Descriptor,//g" ${file};
  done
}

function winToLin(){
    line=$(sed -e 's#^C:#/c#' -e 's#\\#/#g' <<< "$1")
    echo $line
}

function linToWin(){
    line=$(sed -e 's#^/c#C:#' -e 's#/#\\#g' <<< "$1")
    echo $line
}

case "$(uname -s)" in

   Darwin)
     echo 'Mac OS X'
     ;;

   Linux)
     echo 'Linux'
     PROTOC_BIN=protoc
     ;;

   CYGWIN*|MINGW32*|MSYS*)
     echo 'MS Windows'
     PROTOC_BIN=${DIR}/../bin/protoc-3.0.0-win32/protoc
     ;;

   # Add here more strings to compare
   # See correspondence table at the bottom of this answer

   *)
     echo 'other OS'
     ;;
esac

# Commented because of lags: rm -rf ${PROTOGEN_DIR}

# Generate files for each proto package directory.
for dir in `find ${PROTOBUF_DIR} -type d`; do
  if [[ "$dir" == ${PROTOGEN_DIR} ]]; then
      continue
  fi
  if [ -n "$(ls $dir/*.proto 2>/dev/null)" ]; then
    proto_build_dir ${dir} || exit 1
  fi
done
