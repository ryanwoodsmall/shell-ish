# python
if [ -z "${DEF_PY_VER}" ] ; then
  export DEF_PY_VER=$(echo -e 'import sys\nprint str(sys.version_info[0]) + "." + str(sys.version_info[1])' | python)
fi
export PATH="${PATH}:${HOME}/Library/Python/${DEF_PY_VER}/bin"
