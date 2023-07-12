#!/usr/bin/env bash

H_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/calltouch/"

echo "${H_DIR}"

cd "${H_DIR}" || exit

modules=(disk intranet tasks)
for i in "${modules[@]}"
do
  components_dir=$(ls "${H_DIR}"local/modules/"$i"/install/components/bitrix)
  for entry in $components_dir
  do
    ln -s "${H_DIR}"local/modules/"$i"/install/components/bitrix/"$entry" "${H_DIR}"local/components/bitrix/"$entry"

    echo "${H_DIR}"local/modules/"$i"/install/components/bitrix/"$entry"
  done
done

echo "Симлинки актуализированы для компонентов"
