#!/bin/bash

# Updated to require root user
if [[ $(id -u) -ne 0 ]] ; then echo "Please run as root" ; exit 1 ; fi

# Check required parameters number
if [ $# -ne 1 ]; then
    echo "Illegal number of parameters"
    exit 1
fi

# Configuration
DISTRIBUTION=$1
FILE=./templates/${DISTRIBUTION}

# Check file exist
if [ ! -f ${FILE} ]
then
    echo "File does not exist"
    exit 2
fi

# Add Vagrant's NFS setup commands to sudoers, for `vagrant up` without a password
# Updated to work with Vagrant 1.3.x

# Stage updated sudoers in a temporary file for syntax checking
TMP=$(mktemp -t vagrant_sudoers_XXX)

cat /etc/sudoers > ${TMP}

# Allow passwordless startup of Vagrant when using NFS.
# https://github.com/mitchellh/vagrant/blob/master/contrib/sudoers
cat ${FILE} >> ${TMP}

# Check syntax and overwrite sudoers if clean
visudo -c -f ${TMP}
if [ $? -eq 0 ]; then
  echo "Adding vagrant commands to sudoers"
  cat ${TMP} > /etc/sudoers
else
  echo "sudoers syntax wasn't valid. Aborting!"
fi

rm -f ${TMP}
