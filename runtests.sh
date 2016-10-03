cd data/ai
../../lua/lua boot.lua

for file in `find .`
do
    EXTENSION="${file##*.}"

    if [ "$EXTENSION" == "lua" ]
    then
        RESULTS=`../../luac -p $file`

        if [ "$RESULTS" != "No syntax errors detected in $file" ]
        then
            echo $RESULTS
        fi
    fi
done
