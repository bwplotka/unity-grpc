#!/bin/bash
# Generates protobuf Go datastructures from the proto directory.

#set -o xtrace

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
PROTOBUF_DIR=${PROTOBUF_DIR-${DIR}/proto}
PROTOGEN_DIR=go-server/model
GENERATION_DIR=${GENERATION_DIR-${DIR}/${PROTOGEN_DIR}}
IMPORT_PREFIX="github.com/Bplotka/unity-grpc/example/${PROTOGEN_DIR}"

# OS specific vars.
PROTOC_BIN=

# Builds all .proto files in a given package directory.
# NOTE: All .proto files in a given package must be processed *together*, otherwise the self-referencing
# between files in the same proto package will not work. plugins=grpc:${GENERATION_DIR}
function proto_build_dir {
  DIR_FULL=${1}
  DIR_REL=${1##${PROTOBUF_DIR}}
  DIR_REL=${DIR_REL#/}
  echo -n "proto_build: $DIR_REL "
  mkdir -p ${GENERATION_DIR}/${DIR_REL} 2> /dev/null
  PATH=${GOPATH}/bin:$PATH ${PROTOC_BIN}\
    --proto_path=${PROTOBUF_DIR} \
    --proto_path=${GOPATH}/src/github.com/google/protobuf/src \
    --proto_path=${GOPATH}/src \
    --go_out=plugins=grpc:. \
    ${DIR_FULL}/*.proto || exit $?
  echo "DONE"
  # This is because protoc-gen-go is borked on windows
  mv ${DIR}/*.pb.go ${GENERATION_DIR}/${DIR_REL}
  fix_imports ${GENERATION_DIR}/${DIR_REL}
  echo "Fixed imports."
}

function fix_imports {
  DIR_FULL=${1}
  for file in $(ls ${DIR_FULL}/*.go 2>/dev/null); do
    # This is a massive hack (prefix of "go-sps")
    # See https://github.com/golang/protobuf/issues/63
    sed --in-place='' -r "s~^import(.*) \"example(.*)\"$~import \1 \"${IMPORT_PREFIX}/example\2\"~" ${file};
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

echo "Installing plugins"
go get github.com/golang/protobuf/protoc-gen-go

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
