WORK_DIR=$(cd "$(dirname "$0")"; pwd)

# Check if absolute path is given for PATH_A
if [[ "$1" = /* ]]; then
    PATH_A=$1
else
    PATH_A=$(pwd)/$1
fi

# Check if absolute path is given for PATH_B
if [[ "$2" = /* ]]; then
    PATH_B=$2
else
    PATH_B=$(pwd)/$2
fi

if test "0" = "1" \
    || test "x-$PATH_A" = "x-" \
    || test "x-$PATH_B" = "x-" \
    ; then
    echo "usage:"
    echo "  sh ZFDirDiff.sh PATH_A PATH_B"
    exit 1
fi

if test "x-$ZFDIRDIFF_VIM" = "x-"; then
    ZFDIRDIFF_VIM=vim
fi

"$ZFDIRDIFF_VIM" -c "call ZFDirDiff(\"$PATH_A\", \"$PATH_B\")"
