//
//  NotificationService.swift
//  Service
//
//  Created by Matteo Corradin on 10/08/21.
//

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
            }else{
                bestAttemptContent.body = NSLocalizedString("no_message", comment: "")
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
                    let matches = Catapush.messages(with: predicate)
                    if matches.count > 0 {
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
