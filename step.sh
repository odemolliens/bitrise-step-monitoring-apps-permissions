#!/usr/bin/env bash
# - The -e option causes the shell to exit immediately if any command exits with a non-zero status.
# - The -o pipefail option causes a pipeline to fail if any command in the pipeline fails, rather than just the last command.
# - The -x option enables verbose mode, which causes the shell to print each command before executing it.
set -eox pipefail

echo "---- CONFIG ----"

# Get current app information from config file or Bitrise inputs
if [ -n "${config_file_path:-}" ]; then
    echo "Getting config from the config file"
    source "$config_file_path"
else
    echo "Getting config from Bitrise inputs"
fi

# Check if config keys are set properly for Android and iOS
if [[ "${check_android:-}" == "yes" && -z "${android_permission_count:-}" ]]; then
    echo "Error: Config keys are not set properly"
    echo "Error: You configured to check the Android part, but android_permission_count is not set"
    exit 1
fi

if [[ "${check_ios:-}" == "yes" && -z "${ios_permission_count:-}" ]]; then
    echo "Error: Config keys are not set properly"
    echo "Error: You configured to check the iOS part, but ios_permission_count is not set"
    exit 1
fi

if [[ "${check_android:-}" == "yes" ]]; then
    if [ ! -d "apk_decompiled" ]; then
        echo "ERROR: Cannot find any decompiled APK"
        exit 1
    fi

    # Count permissions that are in the current build's manifest
    CURRENT_ANDROID_PERMISSION_COUNT=$(grep -o -i "<uses-permission" apk_decompiled/AndroidManifest.xml | wc -l)
    envman add --key "CURRENT_ANDROID_PERMISSION_COUNT" --value "$CURRENT_ANDROID_PERMISSION_COUNT"

    grep "<uses-permission" apk_decompiled/AndroidManifest.xml | sed -e 's/<uses-permission android:name="//g' -e 's/"\/>//g' > list_android_permissions.txt

    cp list_android_permissions.txt "$BITRISE_DEPLOY_DIR/list_android_permissions.txt"
fi

if [[ "${check_ios:-}" == "yes" ]]; then
    if [[ -z "${ios_app_name:-}" ]]; then
        echo "ERROR: Didn't find any iOS app name ios_app_name: $ios_app_name"
        exit 1
    fi

    if [ ! -d "ipa_unzipped" ]; then
        echo "ERROR: Cannot find any unzipped IPA"
        exit 1
    fi

    # Count permissions that are in the current build's Info.plist
    CURRENT_IOS_PERMISSION_COUNT=$(grep -o -i "UsageDescription</key>" ipa_unzipped/Payload/"$ios_app_name".app/Info.plist | wc -l)
    envman add --key "CURRENT_IOS_PERMISSION_COUNT" --value "$CURRENT_IOS_PERMISSION_COUNT"

    grep "UsageDescription</key>" "ipa_unzipped/Payload/$ios_app_name.app/Info.plist" | sed -e 's/<key>//g' -e 's/<\/key>//g' > list_ios_permissions.txt
    cp list_ios_permissions.txt "$BITRISE_DEPLOY_DIR/list_ios_permissions.txt"
fi

echo "---- REPORT ----"

if [ ! -f "quality_report.txt" ]; then
    printf "QUALITY REPORT\n\n\n" > quality_report.txt
fi

printf ">>>>>>>>>>  CURRENT APP PERMISSIONS  <<<<<<<<<<\n" >> quality_report.txt

if [[ ${check_android} == "yes" ]]; then
    printf "Android permission count (from config): $android_permission_count \n" >> quality_report.txt
fi
if [[ ${check_ios} == "yes" ]]; then
    printf "iOS permission count (from config): $ios_permission_count \n" >> quality_report.txt
fi

printf "\n\n" >> quality_report.txt

if [[ ${check_android} == "yes" ]]; then
    printf "   >>>>>>>  ANDROID  <<<<<<< \n" >> quality_report.txt
    if [ $CURRENT_ANDROID_PERMISSION_COUNT -gt $android_permission_count ]; then
        printf "!!! New Android permissions have been added !!!\n" >> quality_report.txt
        printf "You had: $android_permission_count permissions \n" >> quality_report.txt
        printf "And now: $CURRENT_ANDROID_PERMISSION_COUNT permissions \n" >> quality_report.txt
        printf "You can see the list of permissions into list_android_permissions.txt \n\n" >> quality_report.txt
    else
        printf "0 alert \n" >> quality_report.txt
    fi
    printf "\n" >> quality_report.txt
fi

if [[ ${check_ios} == "yes" ]]; then
    printf "   >>>>>>>  IOS  <<<<<<< \n" >> quality_report.txt
    if [ $CURRENT_IOS_PERMISSION_COUNT -gt $ios_permission_count ]; then
        printf "!!! New iOS permissions have been added !!!\n" >> quality_report.txt
        printf "You had: $ios_permission_count permissions \n" >> quality_report.txt
        printf "And now: $CURRENT_IOS_PERMISSION_COUNT permissions \n" >> quality_report.txt
        printf "You can see the list of permissions into list_ios_permissions.txt \n\n" >> quality_report.txt
    else
        printf "0 alert \n" >> quality_report.txt
    fi
    printf "\n" >> quality_report.txt
fi

cp quality_report.txt $BITRISE_DEPLOY_DIR/quality_report.txt || true

if [ $CURRENT_ANDROID_PERMISSION_COUNT -gt $android_permission_count ] || [ $CURRENT_IOS_PERMISSION_COUNT -gt $ios_permission_count ]; then
    echo "ERROR: New permissions have been added"
    exit 1
fi

exit 0
