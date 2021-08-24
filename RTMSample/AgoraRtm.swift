//
//  AgoraRtm.swift
//  RTMSample
//
//  Created by Taisei Sakamoto on 2021/08/24.
//

import Foundation
import AgoraRtmKit

enum LoginStatus {
    case online, offline
}

enum OneToOneMessageType {
    case normal, offline
}

class AgoraRtm: NSObject {
    static let kit = AgoraRtmKit(appId: AppId.id, delegate: nil)
    static var current = "7d07a242ab284583bcff2d04eb34767c"
    static var status: LoginStatus = .offline
    static var oneToOneMessageType: OneToOneMessageType = .normal
    static var offlineMessages = [String: [AgoraRtmMessage]]()
    
    static func updateKit(delegate: AgoraRtmDelegate) {
        guard let kit = kit else {
            return
        }
        kit.agoraRtmDelegate = delegate
    }
    
    static func add(offlineMessage: AgoraRtmMessage, from user: String) {
        guard offlineMessage.isOfflineMessage else {
            return
        }
        var messageList: [AgoraRtmMessage]
        if let list = offlineMessages[user] {
            messageList = list
        } else {
            messageList = [AgoraRtmMessage]()
        }
        messageList.append(offlineMessage)
        offlineMessages[user] = messageList
    }
    
    static func getOfflineMessages(from user: String) -> [AgoraRtmMessage]? {
        return offlineMessages[user]
    }
    
    static func removeOfflineMessages(from user: String) {
        offlineMessages.removeValue(forKey: user)
    }
}

