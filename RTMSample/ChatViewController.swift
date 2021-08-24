//
//  ChatViewController.swift
//  RTMSample
//
//  Created by Taisei Sakamoto on 2021/08/24.
//

import UIKit
import AgoraRtmKit

struct Message {
    var userId: String
    var text: String
}

class ChatViewController: UIViewController, ShowAlertProtocol {
    
    //MARK: Properties
    
    @IBOutlet weak var inputTextField: UITextField!
    @IBOutlet weak var inputViewBottom: NSLayoutConstraint!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var inputContainView: UIView!
    
    lazy var list = [Message]()
    var trmChannel: AgoraRtmChannel?
    
    //MARK: Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addKeyboardObserver()
        updateViews()
        ifLoadOfflineMessages()
        AgoraRtm.updateKit(delegate: self)
    }
}

//MARK: - AgoraRtmDelegate

extension ChatViewController: AgoraRtmDelegate {
    func rtmKit(_ kit: AgoraRtmKit, connectionStateChanged state: AgoraRtmConnectionState, reason: AgoraRtmConnectionChangeReason) {
        showAlert("connection state changed: \(state.rawValue)") { [weak self] (_) in
            if reason == .remoteLogin, let strongSelf = self {
                strongSelf.navigationController?.popToRootViewController(animated: true)
            }
        }
    }
}

//MARK: - AgoraRtmChannelDelegate

extension ChatViewController: AgoraRtmChannelDelegate {
    //チャンネルに誰かが参加した時に発生する
    func channel(_ channel: AgoraRtmChannel, memberJoined member: AgoraRtmMember) {
        DispatchQueue.main.async { [unowned self] in
            self.showAlert("DEBUG: \(member.userId) join")
        }
    }
    
    //誰かがチャンネルから退室した時に発生する
    func channel(_ channel: AgoraRtmChannel, memberLeft member: AgoraRtmMember) {
        DispatchQueue.main.async { [unowned self] in
            self.showAlert("DEBUG: \(member.userId) left")
        }
    }
    
    //チャンネル内でメッセージを受け取ったときに発生する
    func channel(_ channel: AgoraRtmChannel, messageReceived message: AgoraRtmMessage, from member: AgoraRtmMember) {
        <#code#>
    }
}
