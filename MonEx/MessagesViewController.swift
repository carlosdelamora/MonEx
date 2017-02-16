//
//  MessagesViewController.swift
//  MonEx
//
//  Created by Carlos De la mora on 2/14/17.
//  Copyright © 2017 carlosdelamora. All rights reserved.
//

import UIKit
import Firebase

class MessagesViewController: UIViewController{
    
    var keyboardOnScreen = false
    var offer: Offer?
    let appUser = AppUser.sharedInstance
    let cellId = "messagesCell"
    var messagesArray: [messages] = [messages]()
    //TODO remove this reference
    var referenceToMessages : FIRDatabaseReference!
    
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var messageTextField: UITextField!
    @IBOutlet weak var bottomView: UIView!
    @IBOutlet weak var collectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        referenceToMessages = FIRDatabase.database().reference().child("messages/\(offer!.bidId!)")
        //observe the messages
        observeMessages()
        
        collectionView.contentInset.top = 8
        collectionView.contentInset.bottom = 20
        collectionView.register(MessagesCollectionViewCell.self, forCellWithReuseIdentifier: cellId)
        
        
        collectionView.dataSource = self
        collectionView.delegate = self
        sendButton.setTitle(NSLocalizedString("Send", comment: "Send:ChatViewController"), for: .normal)
        messageTextField.placeholder = NSLocalizedString("Enter message...", comment: "Enter message...")
        bottomView.layer.borderColor = UIColor(colorLiteralRed: 220/255, green: 220/255, blue: 220/255, alpha: 1).cgColor
        bottomView.layer.borderWidth = 1
        
        messageTextField.delegate = self
        subscribeToNotification(NSNotification.Name.UIKeyboardWillShow.rawValue, selector: #selector(keyboardWillShow))
        subscribeToNotification(NSNotification.Name.UIKeyboardWillHide.rawValue, selector: #selector(keyboardWillHide))
        subscribeToNotification(NSNotification.Name.UIKeyboardDidShow.rawValue, selector: #selector(keyboardDidShow))
        subscribeToNotification(NSNotification.Name.UIKeyboardDidHide.rawValue, selector: #selector(keyboardDidHide))
        
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        unsubscribeFromAllNotifications()
        
    }
    
    @IBAction func backButton(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func sendButton(_ sender: Any) {
        
        //we abvoid sending empty messages
        guard messageTextField.text?.replacingOccurrences(of: " ", with: "") != "" else{
            return
        }
        
        let childReference = referenceToMessages.childByAutoId()
        let now = Date()
        let timesStamp = now.timeIntervalSince1970 as NSNumber
        let values = [Constants.messages.text: messageTextField.text!, Constants.messages.fromId: appUser.firebaseId, Constants.messages.toId: offer!.authorOfTheBid!, Constants.messages.timeStamp: timesStamp as NSNumber] as [String : Any]
        childReference.updateChildValues(values)
        
        resignIfFirstResponder(messageTextField)
        messageTextField.text = ""
        
    }
    
    func scrollDown(){
        let indexPath = IndexPath(item: messagesArray.count, section: 0)
        DispatchQueue.main.async {
            self.collectionView.scrollToItem(at: indexPath, at: .top, animated: true)
        }
    }
    
    func observeMessages(){
        
        referenceToMessages.observe(.childAdded, with: { (snapshot) in
            
            guard let messageDictionary = snapshot.value as? [String: Any] else{
                return
            }
            
            guard let message = messages(messageDictionary) else{
                return
            }
            
            self.messagesArray.append(message)
            DispatchQueue.main.async {
                self.collectionView.reloadData()
                
            }
        })
    
    }
}


extension MessagesViewController: UICollectionViewDataSource{
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messagesArray.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! MessagesCollectionViewCell
        let message = messagesArray[indexPath.row]
        cell.textView.text = message.text
        
        setUpCell(cell: cell, message: message)
        cell.bubleWidthAnchor?.constant = estimateFrameForText(text: message.text).width + 42
        return cell
    }
    
    private func setUpCell(cell:MessagesCollectionViewCell, message: messages){
        //check if the messages are from the buyer to be autgoing blue
        if message.fromId == appUser.firebaseId{
            cell.bubbleView.backgroundColor = Constants.color.messagesBlue
            cell.textView.textColor = .white 
        }else{
            // the outgoing messages are grey
            cell.bubbleView.backgroundColor = .lightGray
            cell.textView.textColor = .black
        }
    }
}

extension MessagesViewController: UICollectionViewDelegate{
    
}

extension MessagesViewController: UICollectionViewDelegateFlowLayout{
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        var height: CGFloat = 80
        let text = messagesArray[indexPath.item].text
        height = estimateFrameForText(text: text).height + 20
        return CGSize(width: view.frame.width, height: height)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 8
    }
    
    func estimateFrameForText(text: String) -> CGRect{
        let size = CGSize(width: 200, height: 1000)
        let options = NSStringDrawingOptions.usesFontLeading.union(.usesLineFragmentOrigin)
        return NSString(string: text).boundingRect(with: size, options: options, attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 16)], context: nil)
    }
}

extension MessagesViewController: UITextFieldDelegate{
    
    //The function lets the keyboard hide when return is pressed
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    
    func resignIfFirstResponder(_ textField: UITextField) {
        if textField.isFirstResponder {
            textField.resignFirstResponder()
        }
    }
    
    // the function returns the height of the keyboard and deterimens the displacement need it by the view to not cover the text fields
    fileprivate func keyboardHeight(_ notification: Notification) -> CGFloat {
        let userInfo = (notification as NSNotification).userInfo
        let keyboardSize = userInfo![UIKeyboardFrameEndUserInfoKey] as! NSValue
        return keyboardSize.cgRectValue.height
    }
    
    
    func keyboardWillShow(_ notification: Notification) {
        if !keyboardOnScreen && view.frame.origin.y == 0{
            view.frame.origin.y -= keyboardHeight(notification)
            
        }
        
    }
    
    func keyboardWillHide(_ notification: Notification) {
        if keyboardOnScreen && view.frame.origin.y != 0 {
            view.frame.origin.y = 0
        }
    }
    
    func keyboardDidShow(_ notification: Notification) {
        keyboardOnScreen = true
        
    }
    
    func keyboardDidHide(_ notification: Notification) {
        keyboardOnScreen = false
    }
    
    fileprivate func subscribeToNotification(_ notification: String, selector: Selector) {
        NotificationCenter.default.addObserver(self, selector: selector, name: NSNotification.Name(rawValue: notification), object: nil)
    }
    
    fileprivate func unsubscribeFromAllNotifications() {
        NotificationCenter.default.removeObserver(self)
    }
    
}