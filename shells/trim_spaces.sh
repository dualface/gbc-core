CURDIR=$(dirname $(readlink -f $0))

find $CURDIR/../ -name "*.lua" | xargs sed -i -r 's#[ \t]+$##g'

find $CURDIR/../ -name "*.sh" | xargs sed -i -r 's#[ \t]+$##g'

find $CURDIR/../ -name "*.md" | xargs sed -i -r 's#[ \t]+$##g'

find $CURDIR/../ -name "*.c" | xargs sed -i -r 's#[ \t]+$##g'
