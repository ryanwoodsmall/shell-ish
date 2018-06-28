#!/bin/bash

echo -e '
import json
from java.lang import System
print(json.dumps({n: System.getProperty(n) for n in System.getProperties().stringPropertyNames()}))
' | jython
