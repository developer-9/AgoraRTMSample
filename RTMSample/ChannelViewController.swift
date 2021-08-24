//
//  ChannelViewController.swift
//  RTMSample
//
//  Created by Taisei Sakamoto on 2021/08/24.
//

import UIKit
import AgoraRtmKit

//MARK: - ShowAlertProtocol

protocol ShowAlertProtocol: UIViewController {
    func showAlert(_ message: String, handler: ((UIAlertAction) -> Void)?)
    func showAlert(_ message: String)
}

extension ShowAlertProtocol {
    func showAlert(_ message: String, handler: ((UIAlertAction) -> Void)?) {
        view.endEditing(true)
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: handler))
        present(alert, animated: true, completion: nil)
    }
    
    func showAlert(_ message: String) {
        showAlert(message, handler: nil)
    }
}

//MARK: - ChannelViewController

class ChannelViewController: UIViewController, ShowAlertProtocol {
    
    //MARK: - Properties
    
    @IBOutlet weak var channelTextField: UITextField!
    
    //MARK: - Lifecycle
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        AgoraRtm.updateKit(delegate: self)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        view.endEditing(true)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let identifier = segue.identifier, let channel = sender as? String else { return }
        
        switch identifier {
        case "channelToChat":
            let chatVC = segue.destination as! ChatViewController
            chatVC.channelName = channel
        default:
            break
        }
    }
    
    //MARK: - Actions
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }
    
    @IBAction func doJoinPressed(_ sender: UIButton) {
        guard let channel = channelTextField.text else { return }
        login()
        performSegue(withIdentifier: "channelToChat", sender: channel)
    }
    
    //MARK: - Helpers
    
    private func login() {
        let account = AgoraRtm.current
        
        AgoraRtm.kit?.login(byToken: nil, user: account, completion: { [unowned self] (errorCode) in
            guard errorCode == .ok else {
                self.showAlert("DEBUG: Login error: \(errorCode.rawValue)")
                return
            }
            
            AgoraRtm.status = .offline
        })
    }
}


//MARK: - AgoraRtmDelegate

extension ChannelViewController: AgoraRtmDelegate {
    //SDKとAgoraRTMシステム間のコネクションステータスが変わったときに発生する
    func rtmKit(_ kit: AgoraRtmKit, connectionStateChanged state: AgoraRtmConnectionState, reason: AgoraRtmConnectionChangeReason) {
        showAlert("connection state changed: \(state.rawValue)") { [weak self] (_) in
            if reason == .remoteLogin, let strongSelf = self {
                strongSelf.navigationController?.popToRootViewController(animated: true)
            }
        }
    }
}
