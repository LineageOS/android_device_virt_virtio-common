#!/bin/bash -e

calculate_fat32_image_size() {
    # Constants
    local bytes_per_sector=512
    local sectors_per_cluster=1  # 512B cluster size
    local reserved_sectors=32
    local num_fats=2
    local root_dir_entries=512  # Max root dir entries for estimation

    # Function to count files and directories and calculate total file size
    count_files_dirs_and_size() {
        local path=$1
        local file_count=0
        local dir_count=0
        local total_size=0

        while IFS= read -r -d '' entry; do
            if [[ -f "$entry" ]]; then
                ((file_count++))
                total_size=$((total_size + $(stat -c%s "$entry")))
            elif [[ -d "$entry" ]]; then
                ((dir_count++))
            fi
        done < <(find "$path" -print0)

        echo "$file_count $dir_count $total_size"
    }

    # Initialize counts and total size
    local total_files=0
    local total_dirs=0
    local total_file_size=0

    # Process each argument (path)
    for path in "$@"; do
        if [[ -d "$path" ]]; then
            counts=$(count_files_dirs_and_size "$path")
            total_files=$((total_files + $(echo $counts | cut -d ' ' -f 1)))
            total_dirs=$((total_dirs + $(echo $counts | cut -d ' ' -f 2)))
            total_file_size=$((total_file_size + $(echo $counts | cut -d ' ' -f 3)))
        elif [[ -f "$path" ]]; then
            ((total_files++))
            total_file_size=$((total_file_size + $(stat -c%s "$path")))
        fi
    done

    # Calculate sectors needed for root directory entries
    local root_dir_sectors=$(( (root_dir_entries * 32 + bytes_per_sector - 1) / bytes_per_sector ))

    # Estimate total number of clusters needed
    local total_clusters=$(( (total_files + total_dirs + sectors_per_cluster - 1) / sectors_per_cluster ))

    # FAT size calculation
    local fat_size=$(( (total_clusters * 4 + bytes_per_sector - 1) / bytes_per_sector ))

    # Total FAT32 metadata size
    local metadata_size=$(( (reserved_sectors + num_fats * fat_size + root_dir_sectors) * bytes_per_sector ))

    # Total image size
    local total_image_size=$((metadata_size + total_file_size))

	if [ "$DEBUG" ]; then
		echo "Total files: $total_files"
		echo "Total directories: $total_dirs"
		echo "Total file size: $total_file_size bytes"
		echo "Estimated FAT32 metadata size: $metadata_size bytes"
		echo "Estimated minimal size for FAT32 image: $total_image_size bytes"
	else
		echo -n "$total_image_size"
	fi
}

if [ "$DEBUG" ]; then
	calculate_fat32_image_size $@
else
	FAT32_IMAGE_SIZE_IN_BYTES=$(calculate_fat32_image_size $@)
	FAT32_IMAGE_SIZE_IN_MEGABYTES=$(expr $FAT32_IMAGE_SIZE_IN_BYTES / 1048576)
	expr $FAT32_IMAGE_SIZE_IN_MEGABYTES + 8 # reserve 8 MB
fi
