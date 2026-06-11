#!/usr/bin/env bash

##############################################################################################
#
#   Utility functions that support CI/CD bureaucracies in lambda setups
#
#
##############################################################################################


installDependenciesLambda(){
    # params
    LAMBDA_NAME=${1}
    ROOT_DIR=${2}
    CLEANUP=${3:-true}
    PYTHON_VERSION=${4:-"3.12"}


    # Creation of variables for every needed directory level in the project.
    uuid=$(uuidgen)
    LAMBDA_DIR=${ROOT_DIR}/${LAMBDA_NAME}
    SRC_DIR=${LAMBDA_DIR}/src
    BUILD_DIR=${LAMBDA_DIR}/build

    if [ -d $SRC_DIR ]; then
        printf "Found lambda dir. Proceeding."

        # Remove any possible previous virtualenv.
        cd ${LAMBDA_DIR} && rm -rf ${LAMBDA_NAME}_env && rm -rf ${LAMBDA_NAME}

        # Cleanup any previous code
        cd ${LAMBDA_DIR} && rm -rf ${BUILD_DIR} && mkdir ${BUILD_DIR} && echo finished cleaning build directory

        # Adding python dependencies to target (from virtual environment)
        PYTHON3_PATH=`which python${PYTHON_VERSION}`
        cd ${LAMBDA_DIR} && virtualenv -p $PYTHON3_PATH ${LAMBDA_NAME}_env
        printf "Successfully installed pip virtualenv (python ${PYTHON_VERSION}), sourcing it"

        cd ${LAMBDA_DIR} && source ${LAMBDA_NAME}_env/bin/activate
        # Installation all needed dependencies and libraries
        cd ${LAMBDA_DIR} && python${PYTHON_VERSION} -m pip install --upgrade pip
        cd ${LAMBDA_DIR} && pip${PYTHON_VERSION} install --platform manylinux2014_x86_64 --target ./build/ --python-version ${PYTHON_VERSION} --only-binary=:all: -r requirements.txt

        echo "copying all packages into build"

        cd ${LAMBDA_DIR} && cp -r ${LAMBDA_NAME}_env/lib/python${PYTHON_VERSION}/site-packages/* ${BUILD_DIR} || cp -r ${LAMBDA_NAME}_env/lib/python${PYTHON_VERSION}/dist-packages/* ${BUILD_DIR}
        cd ${SRC_DIR} && cp -r * ${BUILD_DIR}

        echo "Clean up"
        cd ${LAMBDA_DIR} && rm -rf ${LAMBDA_NAME}_env && rm -rf ${LAMBDA_NAME}

        if [ ${CLEANUP} = true ]; then
            echo "Making lambda slimmer..."
            # Cleanup unrequired packages for prod to slim the zip file size.
            if [ -d ${BUILD_DIR}/__pycache__ ]; then
                rm -rf ${BUILD_DIR}/__pycache__
            fi

            if [ -d ${BUILD_DIR}/_pytest ]; then
                rm -rf ${BUILD_DIR}/_pytest
            fi

            if ls ${BUILD_DIR}/pip* 1> /dev/null 2>&1; then
                rm -rf ${BUILD_DIR}/pip*
            fi

            if ls ${BUILD_DIR}/setuptools* 1> /dev/null 2>&1; then
                rm -rf ${BUILD_DIR}/setuptools*
            fi

            if ls ${BUILD_DIR}/*.dist-info 1> /dev/null 2>&1; then
                rm -rf ${BUILD_DIR}/*.dist-info
            fi

        fi

        echo "################################"
        echo "Successfully finished assembling all packages from pip in the correct directory. You may now run make plan or make apply to zip your lambda and deploy remotely"
        echo "################################"

    else
       printf "\nERROR: Unable to build lambda funcion '$LAMBDA_NAME' -  provided path NOT found \n"
    fi
}
