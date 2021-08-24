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
    
    var channelName: String?
    lazy var list = [Message]()
    var trmChannel: AgoraRtmChannel?
    
    //MARK: Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addKeyboardObserver()
        updateViews()
        AgoraRtm.updateKit(delegate: self)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.title = channelName
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        leaveChannel()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    //MARK: Actions
    
    @objc func keyboardFrameWillChange(notification: NSNotification) {
        guard let userInfo = notification.userInfo,
            let endKeyboardFrameValue = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue,
            let durationValue = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber else {
                return
        }
        
        let endKeyboardFrame = endKeyboardFrameValue.cgRectValue
        let duration = durationValue.doubleValue
        
        let isShowing: Bool = endKeyboardFrame.maxY > UIScreen.main.bounds.height ? false : true
        
        UIView.animate(withDuration: duration) { [weak self] in
            guard let strongSelf = self else {
                return
            }
            
            if isShowing {
                let offsetY = strongSelf.inputContainView.frame.maxY - endKeyboardFrame.minY
                guard offsetY > 0 else {
                    return
                }
                strongSelf.inputViewBottom.constant = -offsetY
            } else {
                strongSelf.inputViewBottom.constant = 0
            }
            strongSelf.view.layoutIfNeeded()
        }
    }

    
    //MARK: - Helpers
    
    private func appendMessage(user: String, content: String) {
        DispatchQueue.main.async { [unowned self] in
            
            let msg = Message(userId: user, text: content)
            self.list.append(msg)
            if self.list.count > 100 {
                self.list.removeFirst()
            }
            
            let end = IndexPath(row: self.list.count - 1, section: 0)
            self.tableView.reloadData()
            self.tableView.scrollToRow(at: end, at: .bottom, animated: true)
        }
    }
    
    private func addKeyboardObserver() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardFrameWillChange(notification:)), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
    }
    
    private func updateViews() {
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 55
    }
    
    private func 
}

//MARK: - AgoraRtmDelegate

extension ChatViewController: AgoraRtmDelegate {
    //SDKとAgoraRTMシステム間のコネクションステータスが変わったときに発生する
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
        appendMessage(user: member.userId, content: message.text)
    }
}
