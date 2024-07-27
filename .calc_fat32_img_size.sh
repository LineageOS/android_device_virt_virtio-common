#!/bin/bash

content_size_mb() {
	if [ "$#" -eq 0 ]; then
		echo "Usage: total_size_mb file1 [file2 ... fileN]"
		return 1
	fi

	total_size=0

	for item in "$@"; do
		if [ -e "$item" ]; then
			size=$(du -sm "$item" | cut -f1)
			total_size=$((total_size + size))
		else
			echo "Warning: $item does not exist"
		fi
	done

	echo -n "${total_size}"
}

expr 16 + $(content_size_mb $@)
