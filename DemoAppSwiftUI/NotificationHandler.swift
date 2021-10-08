//
//  Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

final class NotificationHandler: NSObject, UNUserNotificationCenterDelegate {
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void) {
            
            defer {
                completionHandler()
            }
            
            guard let notificationInfo = try? ChatPushNotificationInfo(content: response.notification.request.content),
                  case UNNotificationDefaultActionIdentifier = response.actionIdentifier,
                  let cid = notificationInfo.cid else {
                return
            }
            
            
            
        }
    
}
