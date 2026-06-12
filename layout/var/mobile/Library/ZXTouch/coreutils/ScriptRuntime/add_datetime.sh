#!/var/jb/bin/sh
OUTPUT=/var/mobile/Library/ZXTouch/coreutils/ScriptRuntime/output
echo "$(/var/jb/usr/bin/date '+%m-%d-%Y %T'): Start running script. Script path: $1" >> "$OUTPUT"
while IFS= read -r line; do
    echo "$(/var/jb/usr/bin/date '+%m-%d-%Y %T'): $line" >> "$OUTPUT"
done
