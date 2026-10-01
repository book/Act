#!/bin/bash
set -eu

for distfile in etc/*.dist;
do
    target=$(basename "$distfile" .dist)
    [[ -e "etc/$target" ]] && continue

    if [[ $target == "act.ini" ]]; then
        echo "There is no etc/act.ini."
        echo "Docker Act Entrypoint generates a etc/act.ini for you."
    fi;

    cp "$distfile" "etc/$target"
done

exec "$@"





