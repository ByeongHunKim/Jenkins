#!/bin/bash

# Generate docker image tag by inofi policy
# policy detail:
# * tag format: YYMMDD-${REVISION_NUM}
# * YYMMDD means buildAt time
# * REVISION_NUM should start with 1, and increase count when same YYMMDD revision exist

function main() {
  [[ $# -lt 1 ]] && { echo "> Error: input repository name (e.g. \"./getImageTag.sh inofi-api\")"; exit 1; }

  REPOSITORY_NAME=$1

  CUR_DATE=$(date +'%y%m%d')
  LATEST_TAG=$(aws ecr describe-images --repository-name "$REPOSITORY_NAME" --query "sort_by(imageDetails,& imagePushedAt)[*].imageTags[*]" --no-cli-pager --output text \
                 | tr '\t\r\n' '\n' \
                 | grep "$CUR_DATE" \
                 | sort -r \
                 | head -n 1 \
                 | cut -d '"' -f 2)
  LATEST_TAG_DATE=$(echo $LATEST_TAG | cut -d "-" -f 1)
  if test $LATEST_TAG_DATE && [ "$LATEST_TAG_DATE" -eq "$CUR_DATE" ]; then
    LATEST_TAG_REVISION=$(echo $LATEST_TAG | cut -d "-" -f 2)
    IMAGE_REVISION=$(((LATEST_TAG_REVISION + 1)))
  else
    IMAGE_REVISION=1
  fi

  echo "$CUR_DATE-$IMAGE_REVISION"
}

main "$@"
