set -ex

# Contains a path to this script, relative to the directory it was called from.
RELATIVE_PATH_TO_SCRIPT=$0

# The directory that this script is located in.
TOOL_DIR=`dirname "${RELATIVE_PATH_TO_SCRIPT}"`

echo $TOOL_DIR
