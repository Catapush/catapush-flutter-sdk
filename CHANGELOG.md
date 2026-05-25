## 1.9.0

* Updates minimum supported SDK version to Flutter 3.44 / Dart 3.12.
* Migrates Android plugin to built-in Kotlin (removes explicit `kotlin-android` plugin dependency).

## 1.8.0

* Update Catapush Android SDK to 15.0.0, requires Android target SDK version 35

## 1.7.0

* Update Catapush iOS SDK to 2.2.4
* Update Catapush Android SDK to 14.0.0, requires Android target SDK version 34

## 1.6.3

* Update Catapush iOS SDK to 2.2.3
* Update Catapush Android SDK to 13.0.9

## 1.6.2

* Update Catapush Android SDK to 13.0.5

## 1.6.1

* Update Catapush Android SDK to 13.0.4

## 1.6.0

* Update Catapush Android SDK to 13.0.0, requires Android target SDK version 33

## 1.5.0

* Update Catapush iOS SDK to 2.2.2
* Update Catapush Android SDK to 12.1.1, requires Android compile SDK version 33

## 1.4.0

* Update Catapush iOS SDK to 2.2.1, requires Xcode 14
* Update Catapush Android SDK to 12.0.6

## 1.3.2

* Fixed another race condition in the `catapushNotificationTapped` callback when the app is cold starting on Android

## 1.3.1

* Fixed a race condition in the `catapushNotificationTapped` callback when the app is cold starting on Android

## 1.3.0

* Added the new `catapushNotificationTapped` callback, please review the `SETUP.md` guide to update your app code

## 1.2.1

* Minor improvements

## 1.2.0

* Update Catapush Android SDK to 12.0.0. This is a breaking change, please refer to SETUP.md and the [Catapush Android SDK documentation](https://github.com/Catapush/catapush-docs/blob/master/AndroidSDK/DOCUMENTATION_ANDROID_SDK.md)
* Add the Catapush.shared.stop() method

## 1.1.0

* Update Catapush Android SDK to 11.2.0. This is a breaking change, please refer to SETUP.md

## 1.0.0

* First public release.