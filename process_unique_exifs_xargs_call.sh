#!/bin/bash

source /####/process_unique_exifs_xargs_main.sh

function processPhoto() {
  #echo "Arguments received by processPhoto: $@"
  EXPORT_MSG=""
  INPUT_FILE="$1"
  INFO=$("$EXIF_TOOL" "$INPUT_FILE")
  FILE_NAME=$(echo "$INFO" | grep -e ^File\ Name | cut -c 35-99 | sed 's/ /_/g')

  if [ "$EXPORT_MODE" = true ]; then
    if [ -n $(echo "$INFO" | grep -oE '^(LXLRNT|LLUDWIG)') ]; then
      IMAGE_EXTENSION=$(basename "$FILE_NAME" | awk -F . '{print $NF}')
      FILE_ORI_TIME=$(echo "$INFO" | grep -E "Date/Time Original" | awk '{gsub(/:/,"",$4); gsub(/:/,"",$5); print $4"-"$5}' | head -n 1)
      FILE_MOD_TIME=$(echo "$INFO" | grep -E "File Modification Date/Time" | awk '{gsub(/:/,"",$4); gsub(/:/,"",$5); print $4$5"-"substr($6, 1, 11)}' | sed 's/://g' | sed 's/+//g')
      if [ -n "$FILE_MOD_TIME" ] && [ ${#FILE_MOD_TIME} -gt 7 ]; then
	if [ -n "$FILE_ORI_TIME" ] && [ ${#FILE_ORI_TIME} -gt 7 ]; then
          NEW_FILE_NAME="####_ORI${FILE_ORI_TIME}_MOD${FILE_MOD_TIME}.${IMAGE_EXTENSION}"
	  # else, i.e., if the original timestamp is available, use it to name the folder
	  DATE=$(echo "$FILE_ORI_TIME" | grep -oE "^[0-9]+")
          #EXPORT_MSG=" EXPORT with ORIDATE=${DATE} -- DEBUG: FILE_ORI_TIME=${FILE_ORI_TIME} (Length: ${#FILE_ORI_TIME})"
          EXPORT_MSG=" EXPORT with ORIDATE=${DATE}"
	else
          NEW_FILE_NAME="####_ORI-ISEMPTY_MOD${FILE_MOD_TIME}.${IMAGE_EXTENSION}"
	  # If we can't use the original timestamp for the folder name then use the file modification date
	  DATE=$(echo "$FILE_MOD_TIME" | grep -oE "^[0-9]+")
          #EXPORT_MSG=" EXPORT with MODDATE=${DATE} -- DEBUG: FILE_ORI_TIME=${FILE_ORI_TIME} (Length: ${#FILE_ORI_TIME})"
          EXPORT_MSG=" EXPORT with MODDATE=${DATE}"
        fi
      else	
        echo "Action:\tSKIP -- $INPUT_FILE does not contain valid EXIF attribute File Modification Date/Time"
	return
      fi
    else
      echo "Action:\tSKIP -- $INPUT_FILE does not contain valid any known identifiers for exported images"
      return
    fi
  else
    DATE=$(echo "$INFO" | grep -e Date/Time\ Orig | grep -e :[0-9][0-9]:[0-9][0-9]$ | cut -c 35-44 | sed 's/ /_/g;s/://g')
    DATETIME=$(echo "$INFO" | grep -e Date/Time\ Orig | grep -e :[0-9][0-9]:[0-9][0-9]$ | cut -c 35-99 | sed 's/ /-/g;s/://g')
    CAMERA_MODEL=$(echo "$INFO" | grep -e Camera\ Model\ Name | cut -c 35-99 | sed 's/ /_/g')
    #CAMERA_MODEL=$(echo "$INFO" | grep -i "Camera Model Name" | cut -d ":" -f2 | cut -d ' ' -f3 | sed 's/ //g')
    
    case $CAMERA_MODEL in
      "####")
        RAW_FILE_NAME=$(echo "$INFO" | grep -e ^Raw\ File\ Name | cut -c 35-99 | sed 's/ /_/g')
        NEW_FILE_NAME="${DATETIME}_${CAMERA_MODEL}_${RAW_FILE_NAME}"
        ;;
      "####")
        ORIGINAL_FILE_NAME=$(echo "$INFO" | grep -e ^Original\ File\ Name | cut -c 35-99 | sed 's/ /_/g')
        NEW_FILE_NAME="${DATETIME}_${CAMERA_MODEL}_${ORIGINAL_FILE_NAME}"
        if [[ -z $ORIGINAL_FILE_NAME ]]; then
          IMAGE_EXTENSION=$(basename "$FILE_NAME" | awk -F . '{print $NF}')
          NEW_FILE_NAME="${DATETIME}_${CAMERA_MODEL}.$IMAGE_EXTENSION"
        fi
        ;;
      "####"* | "####"*)
        IMAGE_ID=$(echo "$FILE_NAME" | grep -oE 'LXRW[0-9-]+')
        IMAGE_EXTENSION=$(basename "$FILE_NAME" | awk -F . '{print $NF}')
        CANON_MODEL=$(echo "$INFO" | grep -e "^Canon\ Model" | cut -d ":" -f2 | sed 's/ /_/g; s/-/_/g')
        NEW_FILE_NAME="${DATETIME}${CANON_MODEL}_${IMAGE_ID}.${IMAGE_EXTENSION}"
        ;;
      "####")
        IMAGE_ID=$(echo "$FILE_NAME" | grep -oE '(DSCF|LXA)[0-9]+')
        IMAGE_EXTENSION=$(basename "$FILE_NAME" | awk -F . '{print $NF}')
        NEW_FILE_NAME="${DATETIME}_${CAMERA_MODEL}_${IMAGE_ID}.${IMAGE_EXTENSION}"
        ;;
      "####")
        IMAGE_ID=$(echo "$FILE_NAME" | grep -oE 'P[0-9]+')
        IMAGE_EXTENSION=$(basename "$FILE_NAME" | awk -F . '{print $NF}')
        NEW_FILE_NAME="${DATETIME}_${CAMERA_MODEL}_${IMAGE_ID}.${IMAGE_EXTENSION}"
        ;;
      "####")
        IMAGE_ID=$(echo "$FILE_NAME" | grep -oE '(_|P)[0-9]+')
        if [[  $IMAGE_ID == _* ]]; then
          IMAGE_ID=P$(echo "$IMAGE_ID" | grep -oE '[0-9]+')
        fi
        IMAGE_EXTENSION=$(basename "$FILE_NAME" | awk -F . '{print $NF}')
        NEW_FILE_NAME="${DATETIME}_${CAMERA_MODEL}_${IMAGE_ID}.${IMAGE_EXTENSION}"
        ;;
      "####"|"####"|"####"*)
        IMAGE_EXTENSION=$(basename "$FILE_NAME" | awk -F . '{print $NF}')
        NEW_FILE_NAME="${DATETIME}_${CAMERA_MODEL}.${IMAGE_EXTENSION}"
        ;;
      *)
        [ $DEBUG_MODE = 1 ] && echo -e "Action:\tSKIP -- Model '${CAMERA_MODEL}' not recognised in $FILE_NAME"
        return
        ;;
    esac
  fi

  if [ $DEBUG_MODE = 1 ]; then
    if [ "$REMOVE_SOURCE" = true ]; then
      echo -e "Action:\tMOVE${EXPORT_MSG} $INPUT_FILE to $OUTPUT_DIR/$DATE/$NEW_FILE_NAME"
    else
      echo -e "Action:\tCOPY${EXPORT_MSG} $INPUT_FILE to $OUTPUT_DIR/$DATE/$NEW_FILE_NAME"
    fi
  fi

  if [ "$DRY_RUN" = true ]; then
    if [ "$REMOVE_SOURCE" = true ]; then
      RSYNC_COMMAND="rsync --remove-source-files --dry-run -t -c --stats \"$INPUT_FILE\" \"$OUTPUT_DIR/$DATE/$NEW_FILE_NAME\""
    else
      RSYNC_COMMAND="rsync --dry-run -t -c --stats \"$INPUT_FILE\" \"$OUTPUT_DIR/$DATE/$NEW_FILE_NAME\""
    fi
  else
    [ -d "$OUTPUT_DIR/$DATE" ] || mkdir -p "$OUTPUT_DIR/$DATE"
    if [ "$REMOVE_SOURCE" = true ]; then
      RSYNC_COMMAND="rsync --remove-source-files -t -c --stats \"$INPUT_FILE\" \"$OUTPUT_DIR/$DATE/$NEW_FILE_NAME\""
    else
      RSYNC_COMMAND="rsync -t -c --stats \"$INPUT_FILE\" \"$OUTPUT_DIR/$DATE/$NEW_FILE_NAME\""
    fi

    TRANSFERRED_FILES=$(eval $RSYNC_COMMAND | grep -i "Number *of *files *transferred:" | cut -d \: -f 2 | sed 's/ //g' | tr -d '\n' | cut -d ":" -f2)
    #echo -e "Copied:\t${TRANSFERRED_FILES}"
  fi
}

export -f processPhoto

IFS=' ' read -r -a PHOTO_EXTENSIONS_ARRAY <<< "${PHOTO_EXTENSIONS[@]}"
echo -e "PHOTO_EXTENSIONS: ${PHOTO_EXTENSIONS[@]}\nPHOTO_EXTENSIONS_ARRAY: ${PHOTO_EXTENSIONS_ARRAY}"
TODO=$(find . -type f \( -iname "*.${PHOTO_EXTENSIONS_ARRAY[0]}" $(printf -- '-o -iname "*.%s" ' "${PHOTO_EXTENSIONS_ARRAY[@]:1}") \))

printf "%s\n" "${TODO[@]}" | xargs -I {} -P 8 bash -c 'processPhoto "{}"'

