#!/bin/bash
set -ex

echo "---- CONFIG ----"
# get current app infos
if [ -n "$config_file_path" ]; then
    echo "get config from the config file"
    source $config_file_path
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
    CURRENT_ANDROID_BUILDS_PERMISSIONS_COUNT=$(grep -o -i "<uses-permission" apk_decompiled/AndroidManifest.xml | wc -l)
    if [ $CURRENT_ANDROID_BUILDS_PERMISSIONS_COUNT -gt $android_permission_count ]; then
        ANDROID_PERMISSION_COUNT=$CURRENT_ANDROID_BUILDS_PERMISSIONS_COUNT
        envman add --key ANDROID_PERMISSION_COUNT --value $ANDROID_PERMISSION_COUNT
        grep "<uses-permission" apk_decompiled/AndroidManifest.xml > list_android_permissions.txt
        gsed -ri 's/<uses-permission android:name="//g' list_android_permissions.txt
        gsed -ri 's/"\/>//g' list_android_permissions.txt
        cp list_android_permissions.txt /Users/vagrant/deploy/list_android_permissions.txt
    fi
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
    CURRENT_IOS_BUILDS_PERMISSIONS_COUNT=$(grep -o -i "UsageDescription</key>" ipa_unzipped/Payload/$ios_app_name.app/Info.plist | wc -l)
    if [ $CURRENT_IOS_BUILDS_PERMISSIONS_COUNT -gt $ios_permission_count ]; then
        IOS_PERMISSION_COUNT=$CURRENT_IOS_BUILDS_PERMISSIONS_COUNT
        envman add --key IOS_PERMISSION_COUNT --value $IOS_PERMISSION_COUNT
        grep "UsageDescription</key>" "ipa_unzipped/Payload/$ios_app_name.app/Info.plist" > list_ios_permissions.txt
        gsed -ri 's/<key>//g' list_ios_permissions.txt
        gsed -ri 's/<\/key>//g' list_ios_permissions.txt
        cp list_ios_permissions.txt /Users/vagrant/deploy/list_ios_permissions.txt
    fi
fi

echo "---- REPORT ----"

if [ ! -f "quality_report.txt" ]; then
    printf "QUALITY REPORT\n\n\n" > quality_report.txt
fi

printf ">>>>>>>>>>  CURRENT APP PERMISSIONS  <<<<<<<<<<\n" >> quality_report.txt

if [[ ${check_android} == "yes" ]]; then
    printf "Android permission count : $android_permission_count \n" >> quality_report.txt
fi
if [[ ${check_android} == "yes" ]]; then
    printf "iOS permission count : $ios_permission_count \n" >> quality_report.txt
fi

printf "\n\n" >> quality_report.txt

if [[ ${check_android} == "yes" ]]; then
    printf "   >>>>>>>  ANDROID  <<<<<<< \n" >> quality_report.txt
    if [[ ${ANDROID_PERMISSION_COUNT} != "" ]]; then
        printf "!!! New Android permissions have been added !!!\n" >> quality_report.txt
        printf "We had: $android_permission_count permissions \n" >> quality_report.txt
        printf "And now: $ANDROID_PERMISSION_COUNT permissions \n" >> quality_report.txt
        printf "You can see list of permissions into list_android_permissions.txt \n\n" >> quality_report.txt
    else
        printf "0 alert \n" >> quality_report.txt
    fi
    printf "\n" >> quality_report.txt
fi

if [[ ${check_ios} == "yes" ]]; then
    printf "   >>>>>>>  IOS  <<<<<<< \n" >> quality_report.txt
    if [[ ${IOS_PERMISSION_COUNT} != "" ]]; then
        printf "!!! New iOS permissions have been added !!!\n" >> quality_report.txt
        printf "We had: $ios_permission_count permissions \n" >> quality_report.txt
        printf "And now: $IOS_PERMISSION_COUNT permissions \n" >> quality_report.txt
        printf "You can see list of permissions into list_ios_permissions.txt \n\n" >> quality_report.txt
    else
        printf "0 alert \n" >> quality_report.txt
    fi
    printf "\n" >> quality_report.txt
fi

cp quality_report.txt /Users/vagrant/deploy/quality_report.txt || true

if [[ ${ANDROID_PERMISSION_COUNT} != "" || ${IOS_PERMISSION_COUNT} != "" ]]; then
    echo "Generate an error due to new permissions"
    exit 1
fi
exit 0