#!/bin/bash

# Possible argument {up,down}

arg=$1

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/" && pwd )"
ROOT_DIR=${SCRIPT_DIR}/../../../
JOB=hifimagnet_test_generic
APP=hifimagnet_test
UPLOAD_DIR=${SCRIPT_DIR}/upload
TOSCA=blueprint.yaml
LOCAL=local-blueprint-inputs.yaml
#LOCAL_DIR=../../../../
LOCAL_DIR=../

NO_DEBUG=""
DEBUG=${2:-${NO_DEBUG}} # from "-v" to "-vvv"

echo "DEBUG=$DEBUG"

if [ ! -f "${ROOT_DIR}/${LOCAL}" ]; then
    echo "${ROOT_DIR}/${LOCAL} does not exist! See doc or blueprint examples!"
    exit 1
fi

cd ${UPLOAD_DIR}

case $arg in
    "up" )
        cfy blueprints upload ${DEBUG} -b "${JOB}" "${TOSCA}"
	isOK=$?
	if [ $isOK != 0 ]; then
	   exit 1
	fi
        # read -n 1 -s -p "Press any key to continue"
        # echo ''
        cfy deployments create ${DEBUG} -b "${JOB}" -i "${LOCAL_DIR}/${LOCAL}" --skip-plugins-validation ${JOB}
	isOK=$?
	if [ $isOK != 0 ]; then
	   exit 1
	fi
        # read -n 1 -s -p "Press any key to continue"
        # echo ''
        cfy executions start ${DEBUG} -d "${JOB}" install
	isOK=$?
	if [ $isOK != 0 ]; then
	   exit 1
	fi
        read -n 1 -s -p "Press any key to continue"
        echo ''
        cfy executions start ${DEBUG} -d "${JOB}" run_jobs
        ;;

    "down" )
        echo "Uninstalling deployment ${JOB}..."
        cfy executions start -d "${JOB}" uninstall
        echo "Deleting deployment ${JOB}..."
        cfy deployments delete "${JOB}"
        echo "Deleting blueprint ${JOB}..."
        cfy blueprints delete "${JOB}"
        ;;

    "pkg")
        cd ${SCRIPT_DIR}
        echo "Creating package..."
        export COPYFILE_DISABLE=1
        tar --transform s/^upload/${APP}/ -cvzf "${APP}.tar" upload
        ;;

    *)
        echo "arg: $arg"
        echo "usage: $0 [option]"
        echo ""
        echo "options:"
        echo "      up     send to orchestrator"
        echo "    down     remove from orchestrator"
        echo "     pkg     create a package for marketplace (For portal usage)"
        echo ""
        ;;
esac
