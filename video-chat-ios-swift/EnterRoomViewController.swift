//
//  EnterRoomViewController.swift
//  Basic-Video-Chat
//
//  Created by iujie on 21/02/2022.
//  Copyright © 2022 tokbox. All rights reserved.
//

import UIKit

class EnterRoomViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

    }
 
    @IBOutlet weak var roomNameTextField: UITextField!
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let roomNameText: String = roomNameTextField.text!
        let roomViewController = segue.destination as! RoomViewController
        roomViewController.modalPresentationStyle = .fullScreen
        roomViewController.roomName = roomNameText
    }
    override func shouldPerformSegue(withIdentifier identifier: String,
                            sender: Any?) -> Bool{
        
        let roomNameText: String = roomNameTextField.text!
        if identifier == "roomViewControllerSegue" {
            if roomNameText == "" {
                showSimpleAlert();
                return false
            }
            return true
        }

        return true
    }
    
    func showSimpleAlert() {
        let alert = UIAlertController(title: "Missing room name", message: "Please enter a room name",         preferredStyle: UIAlertController.Style.alert)

        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertAction.Style.default, handler: { _ in
            // No action required
        }))
        alert.addAction(UIAlertAction(title: "Ok",
                                      style: UIAlertAction.Style.default,
                                      handler: {(_: UIAlertAction!) in
                                        //No action required
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
}
