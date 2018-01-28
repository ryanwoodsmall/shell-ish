#!/bin/bash

# https://blog.codecentric.de/en/2012/07/useful-jvm-flags-part-3-printing-all-xx-flags-and-their-values/
# http://stackoverflow.com/questions/10486375/print-all-jvm-flags
# http://stackoverflow.com/questions/5317152/getting-the-parameters-of-a-running-jvm

java -server \
  -XshowSettings:all \
  -XX:+UnlockExperimentalVMOptions \
  -XX:+UnlockDiagnosticVMOptions \
  -XX:+PrintFlagsFinal \
  -version 2>&1
