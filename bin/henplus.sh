#!/bin/bash

#
# henplus wrapper
#   assumes:
#     - henplus is in ~/Downloads/github/neurolabs/henplus and "ant jar" has been run
#     - java-readline is in ~/Downloads/github/aclemons/java-readline and "mvn install ; env JAVA_HOME=... make" has been run
#     - jdbc jars are copied or symlinked into ~/Downloads/jdbc
#

henplusdir="${HOME}/Downloads/github/neurolabs/henplus"
javareadline="${HOME}/Downloads/github/aclemons/java-readline"
#mssqljdbc="${HOME}/Downloads/mssql/mssqljdbc.jar"
#classpath="${javareadline}:${mssqljdbc}"
jdbcdir="${HOME}/Downloads/jdbc"
classpath="$(find ${javareadline} ${jdbcdir} ! -type d -name \*.jar | xargs echo | tr ' ' ':')"

env LD_LIBRARY_PATH="${javareadline}" CLASSPATH="${classpath}" "${henplusdir}/bin/henplus" "${@}"

