
if test "x-$ZFDIRDIFF_IGNORE_SPACE" = "x-1" ; then
    diff --brief "$1" "$2"
else
    diff --brief -b -B "$1" "$2"
fi

