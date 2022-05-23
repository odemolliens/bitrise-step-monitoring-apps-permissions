#!/bin/bash
set -ex

echo "---- CONFIG ----"
# get current app infos
if [ -n "$config_file_path" ]; then
    echo "get config from the config file"
    source "$config_file_path"
else
    echo "get config from bitrise input"
fi

if [[ ${check_android} == "yes" && ${android_permission_count} == "" ]]; then
    echo "Error: Config keys are not set preperly"
    echo "Error: You configured to check android part but android_permission_count is not set "
    exit 1
fi

if [[ ${check_ios} == "yes" && ${ios_permission_count} == "" ]]; then
    echo "Error: Config keys are not set preperly"
    echo "Error: You configured to check ios part but ios_permission_count is not set "
    exit 1
fi

if [[ ${check_android} == "yes" ]]; then
    if [ ! -d "apk_decompiled" ]; then
        echo "ERROR: Cannot find any decompiled apk"
        exit 1
    fi

    # PERMISSION CHECK - count permissions which are into current build's manifest
    CURRENT_ANDROID_PERMISSION_COUNT=$(echo $(grep -o -i "<uses-permission" apk_decompiled/AndroidManifest.xml | wc -l))
    
    envman add --key CURRENT_ANDROID_PERMISSION_COUNT --value $CURRENT_ANDROID_PERMISSION_COUNT
    grep "<uses-permission" apk_decompiled/AndroidManifest.xml > list_android_permissions.txt
    gsed -ri 's/<uses-permission android:name="//g' list_android_permissions.txt
    gsed -ri 's/"\/>//g' list_android_permissions.txt
    cp list_android_permissions.txt $BITRISE_DEPLOY_DIR/list_android_permissions.txt
fi

if [[ ${check_ios} == "yes" ]]; then
    if [[ ${ios_app_name} == "" ]]; then
        echo "ERROR: Didn't find any ios app name ios_app_name: $ios_app_name"
        exit 1
    fi
    if [ ! -d "ipa_unzipped" ]; then
        echo "ERROR: Cannot find any decompiled apk"
        exit 1
    fi

    # PERMISSION CHECK - count permissions which are into current info.plist
    CURRENT_IOS_PERMISSION_COUNT=$(echo $(grep -o -i "UsageDescription</key>" ipa_unzipped/Payload/$ios_app_name.app/Info.plist | wc -l))

    envman add --key CURRENT_IOS_PERMISSION_COUNT --value $CURRENT_IOS_PERMISSION_COUNT
    grep "UsageDescription</key>" "ipa_unzipped/Payload/$ios_app_name.app/Info.plist" > list_ios_permissions.txt
    gsed -ri 's/<key>//g' list_ios_permissions.txt
    gsed -ri 's/<\/key>//g' list_ios_permissions.txt
    cp list_ios_permissions.txt $BITRISE_DEPLOY_DIR/list_ios_permissions.txt
fi

echo "---- REPORT ----"

if [ ! -f "quality_report.json" ]; then
  touch "quality_report.json"
  echo "{}" > "quality_report.json"
fi

STEP_KEY="Permissions"
JSON_OBJECT='{ }'
JSON_OBJECT=$(echo "$(jq ". + { "\"$STEP_KEY\"": {} }" <<<"$JSON_OBJECT")")

if [[ ${check_android} == "yes" ]]; then
    JSON_OBJECT=$(echo "$(jq ".$STEP_KEY += { "androidApp": { "oldValue": "$android_permission_count", "value": "$CURRENT_ANDROID_PERMISSION_COUNT", "displayAlert": true } }" <<<"$JSON_OBJECT")")
fi

if [[ ${check_ios} == "yes" ]]; then
    JSON_OBJECT=$(echo "$(jq ".$STEP_KEY += { "iosApp": { "oldValue": "$ios_permission_count", "value": "$CURRENT_IOS_PERMISSION_COUNT", "displayAlert": true } }" <<<"$JSON_OBJECT")")
fi

echo "$(jq ". + $JSON_OBJECT" <<< cat quality_report.json)" > quality_report.json
cp quality_report.json $BITRISE_DEPLOY_DIR/quality_report.json || true

if [ $CURRENT_ANDROID_PERMISSION_COUNT -gt $android_permission_count ]; then
    echo "ERROR: New Android permissions have been added"
    exit 1
fi
if [ $CURRENT_IOS_PERMISSION_COUNT -gt $ios_permission_count ]; then
    echo "ERROR: New iOS permissions have been added"
    exit 1
fi
exit 0