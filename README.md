<img align="right" src="assets/icon.svg" width="150" height="150" >

# Bitrise step - Mobile apps permissions monitoring

Check mobile applications permissions and compare with configured values to be warned when new permissions have been added

You have to launch this step after [apps-decompiler](https://github.com/imranMnts/bitrise-step-apps-decompiler) to have informations from your APK/IPA

We are looking into the APK/IPA to be sure to have the **REAL** information because during the development of a mobile application, many libraries can be used and these can add some permissions or useless heavy resources without the consent of the developer. Like that, we can follow up them and be aware when we have any unwanted changes

<br/>

## Usage

Add this step using standard Workflow Editor and provide required input environment variables.

<br/>

To give to our step the informations about the expected values, you have:
- create a config file (which should be added to your project repository) and set `config_file_path`  to find them. You can find a config example file [here](#config-file-example)
- **OR** set these keys with expected values directly on Bitrise side
  - android_permission_count
  - ios_permission_count

<br/>

## Inputs

The asterisks (*) mean mandatory keys

|Key             |Value type                     |Description    |Default value        
|----------------|-------------|--------------|--------------|
|check_android* |yes/no |Setup - Set yes if you want check Android part|yes|
|check_ios* |yes/no |Setup - Set yes if you want check iOS part|yes|
|ios_app_name* | String |Config - if you want check iOS app, have to set its name, can be found on xcode -> General -> Display Name||
|config_file_path |String |Config file path - You can create a config file (see bellow example) where you can set different needed data to follow up values via your git client - eg. `folder/config.sh` ||
|android_permission_count | String |Config - APK's expected permission count - *not need to set if already set into your config file*||
|ios_permission_count | String |Config - iIPA's expected permission count - *not need to set if already set into your config file*||

<br />

## Outputs

|Key             |Value type    |Description
|----------------|-------------|--------------|
|IOS_PERMISSION_COUNT |String |New generated iOS app's permission count|
|ANDROID_PERMISSION_COUNT |String |New generated Android app's permission count|

<br />

### Config file example

config.sh
```bash
android_permission_count=10
ios_permission_count=5
```
