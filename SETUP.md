# Setup Guide

In order to start sending push notifications and interacting with your mobile app users, follow the instructions below:

1. Create your account by [signing up](https://www.catapush.com/d/register) for Catapush services and register your app on our Private Panel
2. Generate a [iOS Push Certificate](https://www.catapush.com/docs-ios) and a [FCM Push Notification Key](https://github.com/Catapush/catapush-docs/blob/master/AndroidSDK/DOCUMENTATION_PLATFORM_GMS_FCM.md) or a [HMS Push Notification Key](https://github.com/Catapush/catapush-docs/blob/master/AndroidSDK/DOCUMENTATION_PLATFORM_HMS_PUSHKIT.md)
4. [Integrate Flutter SDK](#integrate_flutter_sdk)

## Integrate Flutter SDK

### Add Catapush flutter sdk dependency

Run this command:
With Flutter:
```$ flutter pub add catapush_flutter_sdk```

This will add a line like this to your package's pubspec.yaml (and run an implicit flutter pub get):
```
dependencies:
  catapush_flutter_sdk: ^1.6.0
```

Now, in your Dart code, you can use:
```import 'package:catapush_flutter_sdk/catapush_flutter_sdk.dart';```


### [iOS] Add a Notification Service Extension
In order to process the push notification a Notification Service Extension is required.
Add a Notification Service Extension (in Xcode File -> New -> Target...) that extends ```CatapushNotificationServiceExtension```

```swift
import Foundation
import UserNotifications
import catapush_ios_sdk_pod

let PENDING_NOTIF_DAYS = 5 // Represents the maximum time of cached messages for catapushNotificationTapped callback

extension UNNotificationAttachment {
    static func create(identifier: String, image: UIImage, options: [NSObject : AnyObject]?) -> UNNotificationAttachment? {
        let fileManager = FileManager.default
        let tmpSubFolderName = ProcessInfo.processInfo.globallyUniqueString
        let tmpSubFolderURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(tmpSubFolderName, isDirectory: true)
        do {
            try fileManager.createDirectory(at: tmpSubFolderURL, withIntermediateDirectories: true, attributes: nil)
            let imageFileIdentifier = identifier+".png"
            let fileURL = tmpSubFolderURL.appendingPathComponent(imageFileIdentifier)
            let data = image.pngData()
            try data!.write(to: fileURL)
            let imageAttachment = try UNNotificationAttachment.init(identifier: imageFileIdentifier, url: fileURL, options: options)
            return imageAttachment
        } catch {
        }
        return nil
    }
}

class NotificationService: CatapushNotificationServiceExtension {
    
    var receivedRequest: UNNotificationRequest?
    
    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.receivedRequest = request;
        super.didReceive(request, withContentHandler: contentHandler)
    }

    override func handleMessage(_ message: MessageIP?, withContentHandler contentHandler: ((UNNotificationContent?) -> Void)?, withBestAttempt bestAttemptContent: UNMutableNotificationContent?) {
        if let contentHandler = contentHandler, let bestAttemptContent = bestAttemptContent {
            if (message != nil) {
                bestAttemptContent.body = message!.body;
                if message!.hasMediaPreview(), let image = message!.imageMediaPreview() {
                    let identifier = ProcessInfo.processInfo.globallyUniqueString
                    if let attachment = UNNotificationAttachment.create(identifier: identifier, image: image, options: nil) {
                        bestAttemptContent.attachments = [attachment]
                    }
                }
                // add the following part if you want to enable the catapushNotificationTapped callback
                // START
                let ud = UserDefaults.init(suiteName: (Bundle.main.object(forInfoDictionaryKey: "Catapush") as! (Dictionary<String,String>))["AppGroup"])
                let pendingMessages : Dictionary<String, String>? = ud!.object(forKey: "pendingMessages") as? Dictionary<String, String>
                var newPendingMessages: Dictionary<String, String>?
                if (pendingMessages == nil) {
                    newPendingMessages = Dictionary()
                }else{
                    let now = NSDate().timeIntervalSince1970
                    newPendingMessages = pendingMessages!.filter({ pendingMessage in
                        guard let timestamp = Double(pendingMessage.value.split(separator: "_").last ?? "") else {
                            return false
                        }
                        if (timestamp + Double(PENDING_NOTIF_DAYS*24*60*60)) > now {
                            return true
                        }
                        return false
                    })
                }
                newPendingMessages![self.receivedRequest!.identifier] = "\(message!.messageId ?? "")_\(String(NSDate().timeIntervalSince1970))"
                ud!.setValue(newPendingMessages, forKey: "pendingMessages")
                // END
            }else{
                bestAttemptContent.body = NSLocalizedString("no_message", comment: "");
            }
            
            let request = NSFetchRequest<NSFetchRequestResult>(entityName: "MessageIP")
            request.predicate = NSPredicate(format: "status = %i", MESSAGEIP_STATUS.MessageIP_NOT_READ.rawValue)
            request.includesSubentities = false
            do {
                let msgCount = try CatapushCoreData.managedObjectContext().count(for: request)
                bestAttemptContent.badge = NSNumber(value: msgCount)
            } catch _ {
            }
            
            contentHandler(bestAttemptContent);
        }
    }

    override func handleError(_ error: Error, withContentHandler contentHandler: ((UNNotificationContent?) -> Void)?, withBestAttempt bestAttemptContent: UNMutableNotificationContent?) {
        if let contentHandler = contentHandler, let bestAttemptContent = bestAttemptContent{
            let errorCode = (error as NSError).code
            if (errorCode == CatapushCredentialsError) {
                bestAttemptContent.body = "Please login to receive messages"
            }
            if (errorCode == CatapushNetworkError) {
                bestAttemptContent.body = "Network problems"
            }
            if (errorCode == CatapushNoMessagesError) {
                if let request = self.receivedRequest, let catapushID = request.content.userInfo["catapushID"] as? String {
                    let predicate = NSPredicate(format: "messageId = %@", catapushID)
                    if let matches = Catapush.messages(with: predicate), matches.count > 0 {
                        let message = matches.first! as! MessageIP
                        if message.status.intValue == MESSAGEIP_STATUS.MessageIP_READ.rawValue{
                            bestAttemptContent.body = "Message already read: " + message.body;
                        }else{
                            bestAttemptContent.body = "Message already received: " + message.body;
                        }
                        if message.hasMediaPreview(), let image = message.imageMediaPreview() {
                            let identifier = ProcessInfo.processInfo.globallyUniqueString
                            if let attachment = UNNotificationAttachment.create(identifier: identifier, image: image, options: nil) {
                                bestAttemptContent.attachments = [attachment]
                            }
                        }
                    }else{
                        bestAttemptContent.body = "Open the application to verify the connection"
                    }
                }else{
                    bestAttemptContent.body = "Please open the app to read the message"
                }
            }
            if (errorCode == CatapushFileProtectionError) {
                bestAttemptContent.body = "Unlock the device at least once to receive the message"
            }
            if (errorCode == CatapushConflictErrorCode) {
                bestAttemptContent.body = "Connected from another resource"
            }
            if (errorCode == CatapushAppIsActive) {
                bestAttemptContent.body = "Please open the app to read the message"
            }
            contentHandler(bestAttemptContent);
        }
    }
    
}
```

### [iOS] App Groups
Catapush need that the Notification Service Extension and the main application can share resources.
In order to do that you have to create and enable a specific app group for both the application and the extension.
The app and the extension must be in the same app group.
<img src="https://github.com/Catapush/catapush-ios-sdk-pod/blob/master/images/appgroup_1.png">
<img src="https://github.com/Catapush/catapush-ios-sdk-pod/blob/master/images/appgroup_2.png">

You should also add this information in the App plist and the Extension plist (```group.example.group``` should match the one you used for example ```group.catapush.test``` in the screens):
```objectivec
    <key>Catapush</key>
    <dict>
        <key>AppGroup</key>
        <string>group.example.group</string>
    </dict>
```

### [Android] AndroidManifest.xml setup
Set your Catapush app key declaring this meta-data inside the application node of your `AndroidManifest.xml`:
```xml
<meta-data
    android:name="com.catapush.library.APP_KEY"
    android:value="YOUR_APP_KEY" />
```

_YOUR_APP_KEY_ is the _AppKey_ of your Catapush App (go to your [Catapush App configuration dashboard](https://www.catapush.com/panel/dashboard), select your App by clicking "View Panel" and then click on App details section)

Then you need to declare the Catapush broadcast receiver and a permission to secure its broadcasts.

### [Android] Application class customization

You must initialize Catapush in your class that extends `Application`, implementing the `ICatapushInitializer` interface.

You also have to provide your customized notification style template here.

Your `Application.onCreate()` method should contain the following lines:

```java
public class MyApplication extends MultiDexApplication implements ICatapushInitializer {

    @Override
    public void onCreate() {
        super.onCreate();
        initCatapush();
    }

    @Override
    public void initCatapush() {

        // This is the notification template that the Catapush SDK uses to build
        // the status bar notification shown to the user.
        // Customize this template to fit your needs.
        NotificationTemplate notificationTemplate = new NotificationTemplate.Builder("your.app.package.CHANNEL_ID")
            .swipeToDismissEnabled(true)
            .vibrationEnabled(true)
            .vibrationPattern(new long[]{100, 200, 100, 300})
            .soundEnabled(true)
            .soundResourceUri(RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION))
            .circleColor(Color.BLUE)
            .iconId(R.drawable.ic_stat_notify_default)
            .useAttachmentPreviewAsLargeIcon(true)
            .modalIconId(R.mipmap.ic_launcher)
            .ledEnabled(true)
            .ledColor(Color.BLUE)
            .ledOnMS(2000)
            .ledOffMS(1000)
            .build();

        // This is the Android system notification channel that will be used by the Catapush SDK
        // to notify the incoming messages since Android 8.0. It is important that the channel
        // is created before starting Catapush.
        // Customize this channel to fit your needs.
        // See https://developer.android.com/training/notify-user/channels
        NotificationManager nm = ((NotificationManager) getSystemService(Context.NOTIFICATION_SERVICE));
        if (nm != null && Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            String channelName = "Catapush messages";
            NotificationChannel channel = nm.getNotificationChannel(notificationTemplate.getNotificationChannelId());
            if (channel == null) {
                channel = new NotificationChannel(notificationTemplate.getNotificationChannelId(), channelName, NotificationManager.IMPORTANCE_HIGH);
                channel.enableVibration(notificationTemplate.isVibrationEnabled());
                channel.setVibrationPattern(notificationTemplate.getVibrationPattern());
                channel.enableLights(notificationTemplate.isLedEnabled());
                channel.setLightColor(notificationTemplate.getLedColor());
                if (notificationTemplate.isSoundEnabled()) {
                AudioAttributes audioAttributes = new AudioAttributes.Builder()
                    .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                    .setUsage(AudioAttributes.USAGE_NOTIFICATION_COMMUNICATION_INSTANT)
                    .build();
                channel.setSound(notificationTemplate.getSoundResourceUri(), audioAttributes);
                }
            }
            nm.createNotificationChannel(channel);
        }

        Catapush.getInstance()
            .init(
                this,
                this,
                CatapushFlutterEventDelegate.INSTANCE, // Required, the Flutter plugin won't work if you don't set this depegate instance
                Collections.singletonList(CatapushGms.INSTANCE),
                new CatapushFlutterIntentProvider(MainActivity.class),
                notificationTemplate,
                null,
                new Callback<Boolean>() {
                    @Override
                    public void success(Boolean response) {
                        Log.d("MyApp", "Catapush has been successfully initialized");
                    }

                    @Override
                    public void failure(@NonNull Throwable t) {
                        Log.e("MyApp", "Can't initialize Catapush!", t);
                    }
                });
    }
}
```

If you are defining a custom application class for your app for the first time, remember to add it to your `AndroidManifest.xml`:

```xml
<application
    android:name=".MyApplication"
    android:icon="@mipmap/ic_launcher"
    android:label="@string/app_name"
    android:theme="@style/AppTheme">
```

Please note that, to be used, the `MultiDexApplication` requires your app to depend on the `androidx.multidex:multidex` dependency.

### [Android] MainActivity class customization

Your `MainActivity` implementation must forward the received `Intent`s to make the `catapushNotificationTapped` callback work:

```java
public class MainActivity extends FlutterActivity {

    @Override
    protected void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        CatapushFlutterIntentProvider.Companion.handleIntent(getIntent());
    }

    @Override
    protected void onNewIntent(@NonNull Intent intent) {
        super.onNewIntent(intent);
        CatapushFlutterIntentProvider.Companion.handleIntent(intent);
    }

}
```

The `Intent` instances will be handled only if generated from a Catapush notification.

### [Android] Configure a push services provider

If you want to be able to receive the messages while your app is not running in the foreground you have to integrate one of the supported services providers: Google Mobile Services or Huawei Mobile Services.

- For GMS follow [this documentation section](https://github.com/Catapush/catapush-docs/blob/master/AndroidSDK/DOCUMENTATION_ANDROID_SDK.md#google-mobile-services-gms-module)

- For HMS follow [this documentation section](https://github.com/Catapush/catapush-docs/blob/master/AndroidSDK/DOCUMENTATION_ANDROID_SDK.md#huawei-mobile-services-hms-module)

### [Android] Multiple notification channels

If you want to deliver a message to a specific notification channel you just need to set the `channel` attribute of the Catapush message you are sending to the same ID of the Android notification channel that you have previuosly created in your app.

Then, when you initialize the Catapush Android SDK in your `Application.onCreate(…)` method, pass the main/default `NotificationTemplate` as 3rd argument of the `Catapush.init(…)` method and as 4th argument a `Collection<NotificationTemplate>` containing all the other templates, one for each additional notification channel that you want to use with Catapush.

When a message with the `channel` attribute is received it gets published to the corresponding notification channel if a `NotificationTemplate` with a matchin ID is found, otherwise it will be published using the main/default `NotificationTemplate`.

### Initialize Catapush SDK
You can now initialize the Catapush using the following code in your `main.dart` file:

```dart
// To enable logging to the console
Catapush.shared.enableLog(true);

final init = await Catapush.shared.init(
    ios: iOSSettings('YOUR_APP_KEY'),
);
```

Register `CatapushStateDelegate` and `CatapushMessageDelegate` in order to recieve update regard the state of the connection and the state of the messages.

```dart
Catapush.shared.setCatapushMessageDelegate(_catapushMessageDelegate);
Catapush.shared.setCatapushStateDelegate(_catapushStateDelegate);
```

```dart
abstract class CatapushStateDelegate {
  void catapushStateChanged(CatapushState state);
  void catapushHandleError(CatapushError error);
}
```

```dart
abstract class CatapushMessageDelegate {
  void catapushMessageReceived(CatapushMessage message);
  void catapushMessageSent(CatapushMessage message);
  void catapushNotificationTapped(CatapushMessage message);
}
```

### Basic usage
In order to start Catapush you have to set a user and call the start method.

```dart
Catapush.shared.setUser("identifier", "password");
Catapush.shared.start();
```

To send a message:
```dart
await Catapush.shared.sendMessage(CatapushSendMessage(text: "example"))
```

To receive a message check the `catapushMessageReceived` method of your `CatapushMessageDelegate`.
```dart
@override
void catapushMessageReceived(CatapushMessage message) {
    debugPrint('RECEIVED ${message}');
}
```

To retrieve all received messages:

```dart
final allMessages = await Catapush.shared.allMessages();
```


### Advanced usage
In order to send an attachment, send a read receipt, and more see the demo project in the `/example` folder of this repository.
