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
    
}
