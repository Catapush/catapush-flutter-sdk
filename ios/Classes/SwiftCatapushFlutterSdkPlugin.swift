import Flutter
import UIKit
import CoreServices
import catapush_ios_sdk_pod

public class SwiftCatapushFlutterSdkPlugin: NSObject, FlutterPlugin {
    
    static let catapushStatusChangedNotification = Notification.Name(rawValue: kCatapushStatusChangedNotification)

    var channel: FlutterMethodChannel?
    var catapushDelegate: CatapushDelegateClass?
    var messagesDispatcherDelegate: MessagesDispatchDelegateClass?

    public static func register(with registrar: FlutterPluginRegistrar) {
        let instance = SwiftCatapushFlutterSdkPlugin()
        instance.channel = FlutterMethodChannel(name: "Catapush", binaryMessenger: registrar.messenger())
        registrar.addMethodCallDelegate(instance, channel: instance.channel!)
        registrar.addApplicationDelegate(instance)
        instance.catapushDelegate = CatapushDelegateClass(channel: instance.channel!)
        instance.messagesDispatcherDelegate = MessagesDispatchDelegateClass(channel: instance.channel!)
        
        Catapush.setupCatapushStateDelegate(instance.catapushDelegate, andMessagesDispatcherDelegate: instance.messagesDispatcherDelegate)
        NotificationCenter.default.addObserver(instance, selector: #selector(instance.statusChanged), name: catapushStatusChangedNotification, object: nil)
    }
    
    public func applicationDidBecomeActive(_ application: UIApplication) {
        Catapush.applicationDidBecomeActive(application)
    }
    
    public func applicationWillTerminate(_ application: UIApplication) {
        Catapush.applicationWillTerminate(application)
    }
    
    public func applicationDidEnterBackground(_ application: UIApplication) {
        Catapush.applicationDidEnterBackground(application)
    }
    
    public func applicationWillEnterForeground(_ application: UIApplication) {
        var error: NSError?
        Catapush.applicationWillEnterForeground(application, withError: &error)
        if let error = error {
            // Handle error...
            print("Error: \(error.localizedDescription)")
        }
    }
    
    @objc func statusChanged() {
        var status = ""
        switch Catapush.status() {
        case .CONNECTED:
            status = "connected"
            break
        case .DISCONNECTED:
            status = "disconnected"
            break
        case .CONNECTING:
            status = "connecting"
        default:
            status = "connecting"
        }
        let result :Dictionary<String, String> = [
            "status": status,
        ];
        channel?.invokeMethod("Catapush#catapushStateChanged", arguments: result)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        if "Catapush#init" == call.method {
            if let args = call.arguments as? Dictionary<String, Any>, let ios = args["ios"] as? Dictionary<String, Any> {
                let appId = ios["appId"] as? String
                Catapush.setAppKey(appId)
                Catapush.registerUserNotification(UIApplication.shared.delegate as? UIResponder)
                result(["result": true])
            } else {
                result(FlutterError.init(code: "bad args", message: nil, details: nil))
            }
        }
        if "Catapush#setUser" == call.method {
            if let args = call.arguments as? Dictionary<String, Any>{
                let identifier = args["identifier"] as? String
                let password = args["password"] as? String
                Catapush.setIdentifier(identifier, andPassword: password)
                result(["result": true])
            } else {
                result(FlutterError.init(code: "bad args", message: nil, details: nil))
            }
        }
        if "Catapush#start" == call.method {
            var error: NSError?
            Catapush.start(&error)
            if let error = error {
                result(FlutterError.init(code: "\(error.code)", message: error.localizedDescription, details: error))
            } else {
                result(["result": true])
            }
        }
        if "Catapush#stop" == call.method {
            Catapush.stop()
            result(["result": true])
        }
        if "Catapush#sendMessage" == call.method {
            if let args = call.arguments as? Dictionary<String, Any>, let ios = args["message"] as? Dictionary<String, Any> {
                let text = ios["text"] as? String
                let channel = ios["channel"] as? String
                let replyTo = ios["replyTo"] as? String
                let file = ios["file"] as? Dictionary<String, Any>
                let message: MessageIP?
                if let file = file, let url = file["url"] as? String, let mimeType = file["mimeType"] as? String, FileManager.default.fileExists(atPath: url){
                    let data = FileManager.default.contents(atPath: url)
                    if let channel = channel {
                        if let replyTo = replyTo {
                            message = Catapush.sendMessage(withText: text, andChannel: channel, andData: data, ofType: mimeType, replyTo: replyTo)
                        }else{
                            message = Catapush.sendMessage(withText: text, andChannel: channel, andData: data, ofType: mimeType)
                        }
                    }else{
                        if let replyTo = replyTo {
                            message = Catapush.sendMessage(withText: text, andData: data, ofType: mimeType, replyTo: replyTo)
                        }else{
                            message = Catapush.sendMessage(withText: text, andData: data, ofType: mimeType)
                        }
                    }
                }else{
                    if let channel = channel {
                        if let replyTo = replyTo {
                            message = Catapush.sendMessage(withText: text, andChannel: channel, replyTo: replyTo)
                        }else{
                            message = Catapush.sendMessage(withText: text, andChannel: channel)
                        }
                    }else{
                        if let replyTo = replyTo {
                            message = Catapush.sendMessage(withText: text, replyTo: replyTo)
                        }else{
                            message = Catapush.sendMessage(withText: text)!
                        }
                    }
                }
                result(["result": true, "message": SwiftCatapushFlutterSdkPlugin.formatMessageID(message: message!)])
            } else {
                result(FlutterError.init(code: "bad args", message: nil, details: nil))
            }
        }
        if "Catapush#getAllMessages" == call.method {
            result(["result": (Catapush.allMessages() as! [MessageIP]).map {
                return SwiftCatapushFlutterSdkPlugin.formatMessageID(message: $0)
            }])
        }
        if "Catapush#enableLog" == call.method {
            if let args = call.arguments as? Dictionary<String, Any>{
                let enableLog = args["enableLog"] as! Bool
                Catapush.enableLog(enableLog)
                result(["result": true])
            } else {
                result(FlutterError.init(code: "bad args", message: nil, details: nil))
            }
        }
        if "Catapush#logout" == call.method {
            Catapush.logoutStoredUser(true) {
                result(["result": true])
            } failure: {
                result(["result": true])
            }
            return
        }
        if "Catapush#sendMessageReadNotificationWithId" == call.method {
            if let args = call.arguments as? Dictionary<String, Any>, let id = args["id"] as? String {
                MessageIP.sendMessageReadNotification(withId: id)
                result(["result": true])
            } else {
                result(FlutterError.init(code: "bad args", message: nil, details: nil))
            }
        }
        if "Catapush#getAttachmentUrlForMessage" == call.method {
            if let args = call.arguments as? Dictionary<String, Any>, let id = args["id"] as? String {
                let predicate = NSPredicate(format: "messageId = %@", id)
                if let matches = Catapush.messages(with: predicate), matches.count > 0 {
                    let messageIP = matches.first! as! MessageIP
                    if messageIP.hasMedia() {
                        if messageIP.mm != nil {
                            guard let mime = messageIP.mmType,
                                  let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, mime as CFString, nil),
                                  let ext = UTTypeCopyPreferredTagWithClass(uti.takeRetainedValue(), kUTTagClassFilenameExtension) else{
                               return
                            }
                            let tempDirectoryURL = NSURL.fileURL(withPath: NSTemporaryDirectory(), isDirectory: true)
                            let filePath = tempDirectoryURL.appendingPathComponent("\(messageIP.messageId!).\(ext.takeRetainedValue())")
                            let fileManager = FileManager.default
                            if fileManager.fileExists(atPath: filePath.path) {
                                result(["url": filePath.path, "mimeType": messageIP.mmType])
                            }
                            do {
                                try messageIP.mm.write(to: filePath)
                                result(["url": filePath.path, "mimeType": messageIP.mmType])
                            } catch {
                                result(FlutterError.init(code: "Could not write file", message: error.localizedDescription, details: nil))
                            }
                        }else{
                            messageIP.downloadMedia { (error, data) in
                                if(error != nil){
                                    result(FlutterError.init(code: "Error downloadMedia", message: error?.localizedDescription, details: nil))
                                }else{
                                    let predicate = NSPredicate(format: "messageId = %@", id)
                                    if let matches = Catapush.messages(with: predicate), matches.count > 0 {
                                        let messageIP = matches.first! as! MessageIP
                                        if messageIP.hasMedia() {
                                            if messageIP.mm != nil {
                                                guard let mime = messageIP.mmType,
                                                      let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, mime as CFString, nil),
                                                      let ext = UTTypeCopyPreferredTagWithClass(uti.takeRetainedValue(), kUTTagClassFilenameExtension) else{
                                                    return
                                                }
                                                let tempDirectoryURL = NSURL.fileURL(withPath: NSTemporaryDirectory(), isDirectory: true)
                                                let filePath = tempDirectoryURL.appendingPathComponent("\(messageIP.messageId!).\(ext.takeRetainedValue())")
                                                let fileManager = FileManager.default
                                                if fileManager.fileExists(atPath: filePath.path) {
                                                    result(["url": filePath.path])
                                                }
                                                do {
                                                    try messageIP.mm.write(to: filePath)
                                                    result(["url": filePath.path, "mimeType": messageIP.mmType])
                                                } catch {
                                                    result(FlutterError.init(code: "Could not write file", message: error.localizedDescription, details: nil))
                                                }
                                            }else{
                                                result(["url": ""])
                                            }
                                            return
                                        }else{
                                            result(["url": ""])
                                        }
                                    }else{
                                        result(["url": ""])
                                    }
                                }
                            }
                        }
                        return
                    }else{
                        result(["url": ""])
                    }
                }else{
                    result(["url": ""])
                }
            } else {
                result(FlutterError.init(code: "bad args", message: nil, details: nil))
            }
        }
        
        result(FlutterError.init(code: "no method", message: nil, details: nil))
    }
    
    class CatapushDelegateClass : NSObject, CatapushDelegate{
        
        let channel: FlutterMethodChannel
        
        init(channel: FlutterMethodChannel) {
            self.channel = channel
        }
        
        let LONG_DELAY =  300
        let SHORT_DELAY = 30
        
        func catapushDidConnectSuccessfully(_ catapush: Catapush!) {
            
        }
        
        func catapush(_ catapush: Catapush!, didFailOperation operationName: String!, withError error: Error!) {
            let domain = (error as NSError).domain
            let code = (error as NSError).code
            if domain == CATAPUSH_ERROR_DOMAIN {
                switch code {
                case CatapushErrorCode.INVALID_APP_KEY.rawValue:
                    /*
                     Check the app id and retry.
                     [Catapush setAppKey:@"YOUR_APP_KEY"];
                     */
                    channel.invokeMethod("Catapush#catapushHandleError", arguments: ["event" : "INVALID_APP_KEY", "code": CatapushErrorCode.INVALID_APP_KEY.rawValue])
                    break;
                case CatapushErrorCode.USER_NOT_FOUND.rawValue:
                    /*
                     Please check if you have provided a valid username and password to Catapush via this method:
                     [Catapush setIdentifier:username andPassword:password];
                     */
                    channel.invokeMethod("Catapush#catapushHandleError", arguments: ["event" : "USER_NOT_FOUND", "code": CatapushErrorCode.USER_NOT_FOUND.rawValue])
                    break;
                case CatapushErrorCode.WRONG_AUTHENTICATION.rawValue:
                    /*
                     Please verify your identifier and password validity. The user might have been deleted from the Catapush app (via API or from the dashboard) or the password has changed.

                     You should not keep retrying, delete the stored credentials.
                     Provide a new identifier to this installation to solve the issue.
                     */
                    channel.invokeMethod("Catapush#catapushHandleError", arguments: ["event" : "WRONG_AUTHENTICATION", "code": CatapushErrorCode.WRONG_AUTHENTICATION.rawValue])
                    break;
                case CatapushErrorCode.GENERIC.rawValue:
                    /*
                     An unexpected internal error on the remote messaging service has occurred.
                     This is probably due to a temporary service disruption.
                     Please try again in a few minutes.
                     */
                    self.retry(delayInSeconds: LONG_DELAY);
                    break;
                case CatapushErrorCode.XMPP_MULTIPLE_LOGIN.rawValue:
                    /*
                     The same user identifier has been logged on another device, the messaging service will be stopped on this device
                     Please check that you are using a unique identifier for each device, even on devices owned by the same user.
                     */
                    channel.invokeMethod("Catapush#catapushHandleError", arguments: ["event" : "XMPP_MULTIPLE_LOGIN", "code": CatapushErrorCode.XMPP_MULTIPLE_LOGIN.rawValue])
                    break;
                case CatapushErrorCode.API_UNAUTHORIZED.rawValue:
                    /*
                     The credentials has been rejected    Please verify your identifier and password validity. The user might have been deleted from the Catapush app (via API or from the dashboard) or the password has changed.

                     You should not keep retrying, delete the stored credentials.
                     Provide a new identifier to this installation to solve the issue.
                     */
                    channel.invokeMethod("Catapush#catapushHandleError", arguments: ["event" : "API_UNAUTHORIZED", "code": CatapushErrorCode.API_UNAUTHORIZED.rawValue])
                    break;
                case CatapushErrorCode.API_INTERNAL_ERROR.rawValue:
                    /*
                     Internal error of the remote messaging service
                     
                     An unexpected internal error on the remote messaging service has occurred.
                     This is probably due to a temporary service disruption.
                     Please try again in a few minutes.
                     */
                    self.retry(delayInSeconds: LONG_DELAY);
                    break;
                case CatapushErrorCode.REGISTRATION_BAD_REQUEST.rawValue:
                    /*
                     Internal error of the remote messaging service    An unexpected internal error on the remote messaging service has occurred.
                     This is probably due to a temporary service disruption.
                     Please try again in a few minutes.
                     */
                    self.retry(delayInSeconds: LONG_DELAY);
                    break;
                case CatapushErrorCode.REGISTRATION_FORBIDDEN_WRONG_AUTH.rawValue:
                    /*
                     Wrong auth    Please verify your identifier and password validity. The user might have been deleted from the Catapush app (via API or from the dashboard) or the password has changed.

                     You should not keep retrying, delete the stored credentials.
                     Provide a new identifier to this installation to solve the issue.
                     */
                    channel.invokeMethod("Catapush#catapushHandleError", arguments: ["event" : "REGISTRATION_FORBIDDEN_WRONG_AUTH", "code": CatapushErrorCode.REGISTRATION_FORBIDDEN_WRONG_AUTH.rawValue])
                    break;
                case CatapushErrorCode.REGISTRATION_NOT_FOUND_APPLICATION.rawValue:
                    /*
                     Application not found
                     
                     You appplication is not found or not active.
                     You should not keep retrying.
                     */
                    channel.invokeMethod("Catapush#catapushHandleError", arguments: ["event" : "REGISTRATION_NOT_FOUND_APPLICATION", "code": CatapushErrorCode.REGISTRATION_NOT_FOUND_APPLICATION.rawValue])
                    break;
                case CatapushErrorCode.REGISTRATION_NOT_FOUND_USER.rawValue:
                    /*
                     User not found
                     The user has been probably deleted from the Catapush app (via API or from the dashboard).

                     You should not keep retrying.
                     Provide a new identifier to this installation to solve the issue.
                     */
                    channel.invokeMethod("Catapush#catapushHandleError", arguments: ["event" : "REGISTRATION_NOT_FOUND_USER", "code": CatapushErrorCode.REGISTRATION_NOT_FOUND_USER.rawValue])
                    break;
                case CatapushErrorCode.REGISTRATION_INTERNAL_ERROR.rawValue:
                    /*
                     Internal error of the remote messaging service    An unexpected internal error on the remote messaging service has occurred.
                     This is probably due to a temporary service disruption.
                     Please try again in a few minutes.
                     */
                    self.retry(delayInSeconds: LONG_DELAY);
                    break;
                case CatapushErrorCode.OAUTH_BAD_REQUEST.rawValue:
                    /*
                     Internal error of the remote messaging service    An unexpected internal error on the remote messaging service has occurred.
                     This is probably due to a temporary service disruption.
                     Please try again in a few minutes.
                     */
                    self.retry(delayInSeconds: LONG_DELAY);
                    break;
                case CatapushErrorCode.OAUTH_BAD_REQUEST_INVALID_CLIENT.rawValue:
                    /*
                     Internal error of the remote messaging service    An unexpected internal error on the remote messaging service has occurred.
                     This is probably due to a temporary service disruption.
                     Please try again in a few minutes.
                     */
                    self.retry(delayInSeconds: LONG_DELAY);
                    break;
                case CatapushErrorCode.OAUTH_BAD_REQUEST_INVALID_GRANT.rawValue:
                    /*
                     Internal error of the remote messaging service    An unexpected internal error on the remote messaging service has occurred.
                     This is probably due to a temporary service disruption.
                     Please try again in a few minutes.
                     */
                    self.retry(delayInSeconds: LONG_DELAY);
                    break;
                case CatapushErrorCode.OAUTH_INTERNAL_ERROR.rawValue:
                    /*
                     Internal error of the remote messaging service    An unexpected internal error on the remote messaging service has occurred.
                     This is probably due to a temporary service disruption.
                     Please try again in a few minutes.
                     */
                    self.retry(delayInSeconds: LONG_DELAY);
                    break;
                case CatapushErrorCode.UPDATE_PUSH_TOKEN_FORBIDDEN_WRONG_AUTH.rawValue:
                    /*
                     Credentials error
                     
                     Please verify your identifier and password validity. The user might have been deleted from the Catapush app (via API or from the dashboard) or the password has changed.

                     You should not keep retrying, delete the stored credentials.
                     Provide a new identifier to this installation to solve the issue.
                     */
                    channel.invokeMethod("Catapush#catapushHandleError", arguments: ["event" : "UPDATE_PUSH_TOKEN_FORBIDDEN_WRONG_AUTH", "code": CatapushErrorCode.UPDATE_PUSH_TOKEN_FORBIDDEN_WRONG_AUTH.rawValue])
                    break;
                case CatapushErrorCode.UPDATE_PUSH_TOKEN_FORBIDDEN_NOT_PERMITTED.rawValue:
                    /*
                     Credentials error
                     
                     Please verify your identifier and password validity. The user might have been deleted from the Catapush app (via API or from the dashboard) or the password has changed.

                     You should not keep retrying, delete the stored credentials.
                     Provide a new identifier to this installation to solve the issue.
                     */
                    channel.invokeMethod("Catapush#catapushHandleError", arguments: ["event" : "UPDATE_PUSH_TOKEN_FORBIDDEN_NOT_PERMITTED", "code": CatapushErrorCode.UPDATE_PUSH_TOKEN_FORBIDDEN_NOT_PERMITTED.rawValue])
                    break;
                case CatapushErrorCode.UPDATE_PUSH_TOKEN_NOT_FOUND_CUSTOMER.rawValue:
                    /*
                     Application error
                     
                     You appplication is not found or not active.
                     You should not keep retrying.
                     */
                    channel.invokeMethod("Catapush#catapushHandleError", arguments: ["event" : "UPDATE_PUSH_TOKEN_NOT_FOUND_CUSTOMER", "code": CatapushErrorCode.UPDATE_PUSH_TOKEN_NOT_FOUND_CUSTOMER.rawValue])
                    break;
                case CatapushErrorCode.UPDATE_PUSH_TOKEN_NOT_FOUND_APPLICATION.rawValue:
                    /*
                     Application not found
                     
                     You appplication is not found or not active.
                     You should not keep retrying.
                     */
                    channel.invokeMethod("Catapush#catapushHandleError", arguments: ["event" : "UPDATE_PUSH_TOKEN_NOT_FOUND_APPLICATION", "code": CatapushErrorCode.UPDATE_PUSH_TOKEN_NOT_FOUND_APPLICATION.rawValue])
                    break;
                case CatapushErrorCode.UPDATE_PUSH_TOKEN_NOT_FOUND_USER.rawValue:
                    /*
                     User not found
                     
                     Please verify your identifier and password validity. The user might have been deleted from the Catapush app (via API or from the dashboard) or the password has changed.

                     You should not keep retrying, delete the stored credentials.
                     Provide a new identifier to this installation to solve the issue.
                     */
                    channel.invokeMethod("Catapush#catapushHandleError", arguments: ["event" : "UPDATE_PUSH_TOKEN_NOT_FOUND_USER", "code": CatapushErrorCode.UPDATE_PUSH_TOKEN_NOT_FOUND_USER.rawValue])
                    break;
                case CatapushErrorCode.UPDATE_PUSH_TOKEN_INTERNAL_ERROR.rawValue:
                    /*
                     Internal error of the remote messaging service when updating the push token.
                     
                     Nothing, it's handled automatically by the sdk.
                     An unexpected internal error on the remote messaging service has occurred.
                     This is probably due to a temporary service disruption.
                     */
                    self.retry(delayInSeconds: LONG_DELAY);
                    break;
                case CatapushErrorCode.NETWORK_ERROR.rawValue:
                    /*
                     The SDK couldn’t establish a connection to the Catapush remote messaging service.
                     
                     The device is not connected to the internet or it might be blocked by a firewall or the remote messaging service might be temporarily disrupted.    Please check your internet connection and try to reconnect again.
                     */
                    self.retry(delayInSeconds: SHORT_DELAY);
                    break;
                case CatapushErrorCode.PUSH_TOKEN_UNAVAILABLE.rawValue:
                    /*
                     Push token is not available.
                     
                     Nothing, it's handled automatically by the sdk.
                     */
                    channel.invokeMethod("Catapush#catapushHandleError", arguments: ["event" : "PUSH_TOKEN_UNAVAILABLE", "code": CatapushErrorCode.PUSH_TOKEN_UNAVAILABLE.rawValue])
                    break;
                default:
                    break;
                }
            }
        }
        
        func retry(delayInSeconds:Int) {
            let deadlineTime = DispatchTime.now() + .seconds(delayInSeconds)
            DispatchQueue.main.asyncAfter(deadline: deadlineTime) {
                var error: NSError?
                Catapush.start(&error)
                if error != nil {
                    // API KEY, USERNAME or PASSWORD not set
                }
            }
        }
    }
    
    class MessagesDispatchDelegateClass: NSObject, MessagesDispatchDelegate{
        let channel: FlutterMethodChannel
        
        init(channel: FlutterMethodChannel) {
            self.channel = channel
        }
        
        func libraryDidReceive(_ messageIP: MessageIP!) {
            channel.invokeMethod("Catapush#catapushMessageReceived", arguments: ["message" : formatMessageID(message: messageIP)])
        }
    }
    
    public static func formatMessageID(message: MessageIP) -> Dictionary<String, Any?>{
        let formatter = ISO8601DateFormatter()
    
        return [
            "messageId": message.messageId,
            "body": message.body,
            "sender": message.sender,
            "channel": message.channel,
            "optionalData": message.optionalData(),
            "replyToId": message.originalMessageId,
            "state": getStateForMessage(message: message),
            "sentTime": formatter.string(from: message.sentTime),
            "hasAttachment": message.hasMedia()
        ];
    }
    
    public static func getStateForMessage(message: MessageIP) -> String{
        if message.type.intValue == MESSAGEIP_TYPE.MessageIP_TYPE_INCOMING.rawValue {
            if message.status.intValue == MESSAGEIP_STATUS.MessageIP_READ.rawValue{
                return "RECEIVED_CONFIRMED"
            }
            return "RECEIVED"
        }else{
            return "SENT"
        }
    }

}
