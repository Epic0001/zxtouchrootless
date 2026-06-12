#!/var/jb/bin/sh
OUTPUT=/var/mobile/Library/ZXTouch/coreutils/ScriptRuntime/output
echo "`date '+%m-%d-%Y %T'`: Start running script. Script path: $1" >> "$OUTPUT"
while IFS= read -r line; do
    echo "`date '+%m-%d-%Y %T'`: $line" >> "$OUTPUT"
done
