//
//  ChatViewController.swift
//  RTMSample
//
//  Created by Taisei Sakamoto on 2021/08/24.
//

import UIKit
import AgoraRtmKit

//MARK: - Message

struct Message {
    var userId: String
    var text: String
}

//MARK: - ChatViewController

class ChatViewController: UIViewController, ShowAlertProtocol {
    
    //MARK: - Properties
    
    @IBOutlet weak var inputTextField: UITextField!
    @IBOutlet weak var inputViewBottom: NSLayoutConstraint!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var inputContainView: UIView!
    
    var channelName: String = ""
    lazy var list = [Message]()
    var rtmChannel: AgoraRtmChannel?
    
    //MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addKeyboardObserver()
        updateViews()
        AgoraRtm.updateKit(delegate: self)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.title = channelName
        createChannel(channelName)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        leaveChannel()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    //MARK:  - Actions
    
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
    
    private func leaveChannel() {
        rtmChannel?.leave(completion: { error in
            print("DEBUG: Channel error \(error.rawValue)")
        })
    }
    
    private func pressedReturnToSendText(_ text: String?) -> Bool {
        guard let text = text, text.count > 0 else { return false }
        send(message: text)
        return true
    }
}

//MARK: - Send Message functions

extension ChatViewController {
    private func send(message: String) {
        let sent = { [unowned self] (state: Int) in
            guard state == 0 else {
                self.showAlert("DEBUG: Message error \(state)") { _ in
                    self.view.endEditing(true)
                }
                return
            }
            
            let current = AgoraRtm.current
            self.appendMessage(user: current, content: message)
        }
        
        let rtmMessage = AgoraRtmMessage(text: message)
        rtmChannel?.send(rtmMessage, completion: { error in
            sent(error.rawValue)
        })
    }
}

//MARK: - Channel functions

extension ChatViewController {
    private func createChannel(_ channel: String) {
        let errorHandle = { [weak self] (action: UIAlertAction) in
            guard let strongSelf = self else { return }
            strongSelf.navigationController?.popViewController(animated: true)
        }
        guard let rtmChannel = AgoraRtm.kit?.createChannel(withId: channel, delegate: self) else {
            showAlert("DEBUG: Join channel fail", handler: errorHandle)
            return
        }
        
        rtmChannel.join { [weak self] (error) in
            if error != .channelErrorOk, let strongSelf = self {
                strongSelf.showAlert("DEBUG: Join channel error: \(error.rawValue)",
                                     handler: errorHandle)
            }
        }
        
        self.rtmChannel = rtmChannel
    }
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

//MARK: - UITableViewDataSource

extension ChatViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return list.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let msg = list[indexPath.row]
        let type: CellType = msg.userId == AgoraRtm.current ? .right : .left
        let cell = tableView.dequeueReusableCell(withIdentifier: "MessageCell", for: indexPath) as! MessageCell
        cell.update(type: type, message: msg)
        return cell
    }
}

//MARK: - UITextFieldDelegate

extension ChatViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if pressedReturnToSendText(textField.text) {
            textField.text = nil
        } else {
            view.endEditing(true)
        }
        return true
    }
}
