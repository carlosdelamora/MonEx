//
//  MessagesViewController.swift
//  MonEx
//
//  Created by Carlos De la mora on 2/14/17.
//  Copyright © 2017 carlosdelamora. All rights reserved.
//

import UIKit
import Firebase
import CoreData
import OneSignal
import UserNotificationsUI
import UserNotifications

class MessagesViewController: UIViewController{
    
    var keyboardOnScreen = false
    var offer: Offer?
    let appUser = AppUser.sharedInstance
    let cellId = "messavarCell"
    var messagesArray: [messages] = [messages]()
    //TODO remove this reference
    var referenceToMessages : FIRDatabaseReference!
    var rootReference: FIRDatabaseReference!
    var storageReference: FIRStorageReference!
    var context: NSManagedObjectContext? = nil
    fileprivate var _refHandle: FIRDatabaseHandle!
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    var imageUrlOfTheOther : String?
    var firebaseIdOftheOther: String?
    var acceptOfferViewController: AcceptOfferViewController?
    
    @IBOutlet weak var navigationBar: UINavigationBar!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var messageTextField: UITextField!
    @IBOutlet weak var bottomView: UIView!
    @IBOutlet weak var collectionView: UICollectionView!
    
    @IBOutlet weak var chatItem: UITabBarItem!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        referenceToMessages = FIRDatabase.database().reference().child("messages/\(offer!.bidId!)")
        rootReference = FIRDatabase.database().reference()
        collectionView.contentInset.top = 8
        collectionView.contentInset.bottom = 20
        collectionView.register(MessagesCollectionViewCell.self, forCellWithReuseIdentifier: cellId)
        collectionView.dataSource = self
        collectionView.delegate = self
        sendButton.setTitle(NSLocalizedString("Send", comment: "Send:ChatViewController"), for: .normal)
        bottomView.layer.borderWidth = 1
        bottomView.layer.borderColor = Constants.color.greenLogoColor.cgColor
        
        messageTextField.placeholder = NSLocalizedString("Enter message...", comment: "Enter message...")
        messageTextField.layer.borderColor = Constants.color.greenLogoColor.cgColor//UIColor(colorLiteralRed: 220/255, green: 220/255, blue: 220/255, alpha: 1).cgColor
        messageTextField.layer.borderWidth = 1
        //add a white space to the left of the textField
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 8, height: 30))
        messageTextField.leftView = paddingView;
        messageTextField.leftViewMode = UITextFieldViewMode.always
        
        
        messageTextField.delegate = self
        //set the context for core data
        let stack = appDelegate.stack
        context = stack?.context
        
        //set the title for the navigation bar 
        navigationBar.topItem?.title = offer?.name 
        //set the color of the navigation bar
        navigationBar.barTintColor = Constants.color.greyLogoColor
        
        
        //set a touch action
        let gestureRecognizer = UITapGestureRecognizer(target: self, action:#selector(resignTextFirstResponder))
        collectionView.addGestureRecognizer(gestureRecognizer)
        let otherOffer = getOtherOffer(bidId: (offer?.bidId)!)
        imageUrlOfTheOther = otherOffer?.imageUrlOfOther
        firebaseIdOftheOther = otherOffer?.firebaseIdOther
        
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle{
        return .lightContent
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        //observe the messages evry time the viewAppears
        observeMessages()
        subscribeToNotification(NSNotification.Name.UIKeyboardWillShow.rawValue, selector: #selector(keyboardWillShow))
        subscribeToNotification(NSNotification.Name.UIKeyboardWillHide.rawValue, selector: #selector(keyboardWillHide))
        subscribeToNotification(NSNotification.Name.UIKeyboardDidShow.rawValue, selector: #selector(keyboardDidShow))
        subscribeToNotification(NSNotification.Name.UIKeyboardDidHide.rawValue, selector: #selector(keyboardDidHide))
        configureStorage()
        //let the app delegate now that messages is present so it can handle notifications
        appDelegate.isMessagesVC = true
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        //clear the messages
        self.messagesArray = []
        
        //let the app delegate now that messages is present so it can handle notifications
        appDelegate.isMessagesVC = false
        unsubscribeFromAllNotifications()
        referenceToMessages.removeObserver(withHandle: _refHandle)
    }
    
    @IBAction func backButton(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func terminate(_ sender: Any) {
        //appUser.deleteInfoTerminated(bidId: offer!.bidId!)
        dismiss(animated: true, completion: {
           self.acceptOfferViewController?.goToRating()
            
        })
        sendNotificationOfTermination()
        
        
    }
    
    
    @IBAction func sendButton(_ sender: Any) {
        
        //we abvoid sending empty messages
        guard messageTextField.text?.replacingOccurrences(of: " ", with: "") != "" else{
            return
        }
        
        let childReference = referenceToMessages.childByAutoId()
        let now = Date()
        let timesStamp = now.timeIntervalSince1970 as NSNumber
        let values = [Constants.messages.text: messageTextField.text!, Constants.messages.fromId: appUser.firebaseId, Constants.messages.toId: offer!.firebaseId, Constants.messages.timeStamp: timesStamp as NSNumber] as [String : Any]
        childReference.updateChildValues(values)
        
        resignIfFirstResponder(messageTextField)
        
        
        
        //we use one singnal to posh a notification
        OneSignal.postNotification(["contents": ["en": "\(messageTextField.text!)"],"include_player_ids": ["\(offer!.oneSignalId)"], "content_available": true, "mutable_content": true], onSuccess: { (dic) in
                print("THERE WAS NO ERROR")
            }, onFailure: { (Error) in
                print("THERE WAS AN EROOR \(Error!)")
            })
        messageTextField.text = ""
    }
    
    func sendNotificationOfTermination(){
        // Create a reference to the file to download when the notification is recived
        let imageReference = FIRStorage.storage().reference().child("ProfilePictures/\(appUser.firebaseId).jpg")
        var urlString: String? = nil
        imageReference.downloadURL{ aUrl, error in
            
            if let error = error {
                // Handle any errors
                print("there was an error \(error)")
            }else{
                urlString = "\(aUrl!)"
                
                var contentsDictionary = [String: String]()
                var headingsDictionary = [String: String]()
                var spanishMessage : String = ""
                var portugueseMessage: String = ""
                var spanishTitle: String = ""
                var portugueseTitle: String = ""
                
                //we always need to include a message in English
                contentsDictionary = ["en": "The transaction has been completed"]
                spanishMessage = "La transaccion ha sido terminada"
                portugueseMessage = "A transacção foi encerrada"
                //The heading text
                headingsDictionary = ["en": "Your transaction with \(self.appUser.name) is over"]
                spanishTitle = "So transaccion con \(self.appUser.name) termino"
                portugueseTitle = "Sua transação com \(self.appUser.name) acabou"
                
                contentsDictionary["es"] = spanishMessage
                contentsDictionary["pt"] = portugueseMessage
                headingsDictionary["es"] = spanishTitle
                headingsDictionary["pt"] = portugueseTitle
                
                var subTitileDictionary = ["en": "Terminated"]
                let spansihSubTitle = "Terminada"
                let portugueseSubTitle = "Terminado"
                subTitileDictionary["es"] = spansihSubTitle
                subTitileDictionary["pt"] = portugueseSubTitle
                
                
                
                //we use one signal to push the notification
                OneSignal.postNotification(["contents": contentsDictionary, "headings":headingsDictionary,"subtitle":subTitileDictionary,"include_player_ids": ["\(self.offer!.oneSignalId)"], "content_available": true, "mutable_content": true, "data":["imageUrl": urlString!, "name": "\(self.appUser.name)", "distance": "", "bidId": self.offer?.bidId!, Constants.offer.offerStatus: Constants.offerStatus.complete, Constants.offer.firebaseId: self.appUser.firebaseId],"ios_category": "acceptOffer"], onSuccess: { (dic) in
                    
                    
                    print("THERE WAS NO ERROR")
                }, onFailure: { (Error) in
                    print("THERE WAS AN EROOR \(Error!)")
                })
            }
        }
    }

    
    
    func getOtherOffer(bidId: String) -> OtherOffer?{
        
        var otherOffer: OtherOffer?
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "OtherOffer")
        let predicate = NSPredicate(format: "bidId = %@", argumentArray: [bidId])
        fetchRequest.predicate = predicate
        print("we fetch the request")
        context?.performAndWait {
            
            do{
                if let results = try self.context?.fetch(fetchRequest) as? [OtherOffer]{
                    otherOffer = results.first
                    if otherOffer == nil{
                        
                    }
                }
            }catch{
                fatalError("can not get the photos form core data")
            }
        }
        
        
        return otherOffer
    }
    
    func configureStorage(){
        storageReference = FIRStorage.storage().reference()
    }

    
    
    func observeMessages(){
       _refHandle = referenceToMessages.observe(.childAdded, with: { (snapshot) in
            
            guard let messageDictionary = snapshot.value as? [String: Any] else{
                return
            }
            
            guard let message = messages(messageDictionary) else{
                return
            }
            
            self.messagesArray.append(message)
            DispatchQueue.main.async {
                self.collectionView.reloadData()
                let indexPath = IndexPath(item: self.messagesArray.count - 1, section: 0)
                self.collectionView.scrollToItem(at: indexPath, at: .top, animated: true)
            }
        })
       print("the messages get called outside the viewController if we are in the app ")
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
        cell.bubbleWidthAnchor?.constant = estimateFrameForText(text: message.text).width + 42
        return cell
    }
    
    private func setUpCell(cell:MessagesCollectionViewCell, message: messages){
        //check if the messages are from the buyer to be autgoing blue
        if message.fromId == appUser.firebaseId{
            cell.bubbleView.backgroundColor = Constants.color.messagesBlue
            cell.textView.textColor = .white
            cell.profileView.isHidden = true
            cell.bubbleViewRightAnchor?.isActive = true
            cell.bubbleViewLeftAnchor?.isActive = false

        }else{
            // the incoming messages are grey
            cell.profileView.isHidden = false
            //the authorOfTheBid string is the same as the FirebaseId of the user and is the same as the imageId
            if let firebaseIdOftheOther = firebaseIdOftheOther{
            
                if !cell.profileView.existsPhotoInCoreData(imageId: firebaseIdOftheOther){
                    //if the photo does not exist download it from Firebase 
                    cell.profileView.loadImage(url: imageUrlOfTheOther!, storageReference: storageReference, saveContext: context, imageId: firebaseIdOftheOther)
                }
            }
            
            
            cell.bubbleView.backgroundColor = .lightGray
            cell.textView.textColor = .black
            cell.bubbleViewRightAnchor?.isActive = false
            cell.bubbleViewLeftAnchor?.isActive = true
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
    
    func resignTextFirstResponder(){
        if messageTextField.isFirstResponder{
            messageTextField.resignFirstResponder()
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
            let displacement = (keyboardHeight(notification) - (self.tabBarController?.tabBar.frame.height)!) - 5//5 comes from the size to fit form MessagesChatTabBarViewController
            view.frame.origin.y -= displacement
            
            navigationBar.frame.origin.y += displacement
            
        }
        
    }
    
    func keyboardWillHide(_ notification: Notification) {
        if keyboardOnScreen && view.frame.origin.y != 0 {
            view.frame.origin.y = 0
            navigationBar.frame.origin.y = 0
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


