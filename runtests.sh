cd data/ai
$TRAVIS_BUILD_DIR/lua/lua boot.lua

for file in `find .`
do
    EXTENSION="${file##*.}"

    if [ "$EXTENSION" == "lua" ]
    then
        $TRAVIS_BUILD_DIR/lua/luac -p $file
    fi
done
