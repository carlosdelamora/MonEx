//
//  BrowseOffersViewController.swift
//  MonEx
//
//  Created by Carlos De la mora on 1/31/17.
//  Copyright © 2017 carlosdelamora. All rights reserved.
//

import UIKit
import Firebase
import GoogleMobileAds
import CoreLocation


class BrowseOffersViewController: UIViewController, GADBannerViewDelegate {
    
    let rootReference = FIRDatabase.database().reference()
    let browseCell:String = "BrowseCell"
    let nothingCellId = "NothingFoundCell"
    let loadingCellId = "loadingCell"
    let appUser = AppUser.sharedInstance
    var arrayOfOffers:[Offer] = [Offer]()
    fileprivate var _refHandle: FIRDatabaseHandle!
    var storageReference: FIRStorageReference!
    let getOffers = GetOffers()
    var path: String = Constants.offerBidLocation.offerBidsLocation
    var currentTable: tableToPresent = .browseOffers
    var activity = UIActivityIndicatorView()
    var lookingToBuy:String?
    var lookingToSell: String?
    var firstLoad = true
    
    //baner view a the bottom of the screen
    var bannerView: GADBannerView!
    
    enum tableToPresent{
        case browseOffers
        case myBids
        case myOffersInBid
    }
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var doneButton: UIBarButtonItem!
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //we get a reference of the storage
        configureStorage()
        
        // Register the Nib
        let cellNib = UINib(nibName: browseCell, bundle: nil)
        tableView.register(cellNib, forCellReuseIdentifier: browseCell)
        
        let nothingCellNib = UINib(nibName: nothingCellId, bundle: nil)
        tableView.register(nothingCellNib, forCellReuseIdentifier: nothingCellId)
        
        //let loadingCellNib = UINib(nibName: loadingCellId, bundle: nil)
        tableView.register(LoadingCell.self, forCellReuseIdentifier: loadingCellId)
        
        
        //set the delegate for the tableView
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = 150
        
        //get location of the user
        appUser.getLocation(viewController: self, highAccuracy: true)
        
        //set the color of the navigation bar
        let navigationController = self.navigationController!
        let navigationBar = navigationController.navigationBar
        //navigationController.preferredStatusBarStyle = .lightContent
        navigationBar.barTintColor = Constants.color.greyLogoColor
        
        //set the color of the tableView
        tableView.backgroundColor = Constants.color.greyLogoColor
        
        //set the baner view
        DispatchQueue.main.async {
            self.bannerView = GADBannerView(adSize: kGADAdSizeFullBanner)
            self.constrainsForBanner(banner: self.bannerView)
            self.bannerView.delegate = self
        }
        
        
        //create insets for the table view to display the banner and not cover the cell
        tableView.contentInset = UIEdgeInsetsMake(0, 0, 50, 0)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        //appUser.stopLocationManager()
        let reference = rootReference.child(path)
        reference.removeObserver(withHandle: _refHandle)
        //remove obersever
        removeNotificationOfSettings()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        //get the most current offers
        getTheOffers()
        //subscriveTo settings notification
        registerForNotificationOfSettings()
    }
    
    
    @IBAction func done(_ sender: Any) {
        DispatchQueue.main.async {
            self.dismiss(animated: true, completion: nil)
        }
        
    }
    
    func constrainsForBanner(banner: GADBannerView){
        self.view.addSubview(bannerView)
        banner.translatesAutoresizingMaskIntoConstraints = false
        banner.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        banner.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        banner.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        banner.heightAnchor.constraint(equalToConstant: 50).isActive = true
        
        bannerView.adUnitID = "ca-app-pub-6885601493816488/3043901013"
        bannerView.rootViewController = self
        bannerView.load(GADRequest())
    }
    
    func getTheOffers(){
        addActivityIndicator()
        switch currentTable{
        case .browseOffers:
            path = Constants.offerBidLocation.offerBidsLocation
            _refHandle = getOffers.getArraysOfOffers(path: path,lookingToBuy: lookingToBuy,lookingToSell: lookingToSell, completion:{
                DispatchQueue.main.async {
                    self.setArrayOfOffers()
                    self.tableView.reloadData()
                    self.stopAcivityIndicator()
                }
            })
        case .myBids:
            path = "Users/\(appUser.firebaseId)/Bid"
            _refHandle = getOffers.getMyBidsArray(path: "Users/\(appUser.firebaseId)/Bid", completion:{
                DispatchQueue.main.async {
                    self.setArrayOfOffers()
                    self.tableView.reloadData()
                    self.stopAcivityIndicator()
                }
            })
        case .myOffersInBid:
            print("tihngs to do")
        }

    }
    
    func configureStorage() {
        // TODO: configure storage using your firebase storage
        storageReference = FIRStorage.storage().reference()
    }
    
    func setArrayOfOffers(){
        switch getOffers.currentStatus{
        case .notsearchedYet, .loading, .nothingFound:
             break
        case .results(let list):
            arrayOfOffers = list.sorted(by: {sortOffers(firstOffer: $0, secondOffer: $1)})
        }
    }
    
    func sortOffers(firstOffer:Offer, secondOffer: Offer)-> Bool{
        
        if let firstDistance = distanceToOffer(offer: firstOffer), let secondDistance = distanceToOffer(offer: secondOffer){
            //if the distance are different we return firstDistance < secondDistance, otherwise we continue
            if firstDistance != secondDistance{
                return firstDistance < secondDistance
            }
        }
        //we are here if there was either nil for at least one distance or the distances are equal one to the other
        guard let firstString = firstOffer.timeStamp, let firstTime = Float(firstString), let secondString = secondOffer.timeStamp, let secondTime = Float(secondString) else{
            return true
        }
        
        return firstTime > secondTime
    }
    
    //this functions gives us the distance to the offer
    func distanceToOffer(offer: Offer)-> Double?{
        var distance:Double? = nil
        if let latitude = offer.latitude, let longitude = offer.longitude {
            let sellerLocation = CLLocation(latitude: latitude , longitude: longitude)
            
            if let location = appUser.location {
                distance = sellerLocation.distance(from: location)
            }
        }
        return distance
    }
    
    
    func addActivityIndicator(){
        DispatchQueue.main.async {
            self.activity.translatesAutoresizingMaskIntoConstraints = false
            self.view.addSubview(self.activity)
            self.view.centerXAnchor.constraint(equalTo: self.activity.centerXAnchor).isActive = true
            self.view.centerYAnchor.constraint(equalTo: self.activity.centerYAnchor).isActive = true
            self.activity.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
            self.activity.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
            self.activity.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
            self.activity.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
            //self.activity.widthAnchor.constraint(equalToConstant: 100).isActive = true
            //self.activity.activityIndicatorViewStyle =
            self.activity.activityIndicatorViewStyle = .whiteLarge
            self.activity.backgroundColor = UIColor(white: 0, alpha: 0.25)
            //self.activity.sizeThatFits(CGSize(width: 80, height: 80))
            self.activity.startAnimating()
        }
    }
    
    func stopAcivityIndicator(){
        activity.stopAnimating()
        activity.removeFromSuperview()
        activity.stopAnimating()
    }

}




extension BrowseOffersViewController: UITableViewDataSource, UITableViewDelegate{
    
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == UITableViewCellEditingStyle.delete{
            if case .results( _) = getOffers.currentStatus{
                let offer = arrayOfOffers[indexPath.row]
                if offer.offerStatus.rawValue != Constants.offerStatus.nonActive{
                    canNotDelete()
                    return 
                }
                
                deleteAllTheInfo(bidId: offer.bidId!)
                arrayOfOffers.remove(at: indexPath.row)
                tableView.deleteRows(at: [indexPath], with: .fade)
            }
        }
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]?{
        if currentTable == .myBids{
            return nil
        }
        return [UITableViewRowAction]()
        
    }
    
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch getOffers.currentStatus{
        case .notsearchedYet:
            return 0
        case .loading:
            
            return 1
        case .nothingFound:
            return 1
        case .results( _):
            return arrayOfOffers.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        switch getOffers.currentStatus{
        case .notsearchedYet, .loading:
            let cell = tableView.dequeueReusableCell(withIdentifier: loadingCellId, for: indexPath) as! LoadingCell
            let spiner = cell.viewWithTag(100) as! UIActivityIndicatorView
            spiner.startAnimating()
            return cell
        case .nothingFound:
            let cell = tableView.dequeueReusableCell(withIdentifier: nothingCellId, for: indexPath) as!
            NothingFoundCell
            return cell
        case .results(_):
            let cell = tableView.dequeueReusableCell(withIdentifier: browseCell, for: indexPath) as! BrowseCell
            //we need a reference to the storage to download the pictures from firebase of core data
            cell.storageReference = storageReference
            let offer = arrayOfOffers[indexPath.row]
            cell.configure(for: offer)
            if case currentTable = tableToPresent.myBids{
                //cell.isUserInteractionEnabled = false
                cell.selectionStyle = .none
            }
            
            cell.contentView.backgroundColor = UIColor.clear
            
            let separator:CGFloat = 3
            let whiteRoundedView : UIView = UIView(frame: CGRect(x: separator, y: separator, width: self.view.frame.size.width - 2*separator, height: 150 - 2*separator))
            
            whiteRoundedView.layer.backgroundColor = Constants.color.greyLogoColor.cgColor
            whiteRoundedView.layer.borderColor = Constants.color.greyLogoColor.cgColor
            whiteRoundedView.layer.borderWidth = 1
            whiteRoundedView.layer.masksToBounds = false
            whiteRoundedView.layer.cornerRadius = 5.0
            cell.contentView.addSubview(whiteRoundedView)
            cell.contentView.sendSubview(toBack: whiteRoundedView)
            
            
            return cell
        }
    }
    

    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if case .results( _) = getOffers.currentStatus{
            
            let offer = arrayOfOffers[indexPath.row]
            if case currentTable = tableToPresent.myBids{
                if offer.offerStatus.rawValue == Constants.offerStatus.nonActive{
                    let cell = tableView.cellForRow(at: indexPath) as! BrowseCell
                    self.completion(offer: offer, browseCell: cell)
                    return
                }
                
                self.appUser.getBidStatus(bidId: offer.bidId!, completion: { status in
                    switch status.rawValue{
                    
                        //the case noBid is also included in case that the bidInfo was erased, this could have happened if the bid has expired or possibly if the bid was rejected and did not get the notification. 
                    case Constants.appUserBidStatus.moreThanFiveUserLastToWrite, Constants.appUserBidStatus.moreThanFiveOtherLastToWrite, Constants.appUserBidStatus.noBid:
                        //in this case the we show the transaction has expired and update the bid to non active
                        DispatchQueue.main.async {
                            self.showExpiredAlert()
                        }
                        let pathToUpdate = "/Users/\(self.appUser.firebaseId)/Bid/\(offer.bidId!)/offer/\(Constants.offer.offerStatus)"
                        let lastOfferInBidStatusPath = "offerBidsLocation/\(offer.bidId!)/lastOfferInBid/\(Constants.offer.offerStatus)"
                        self.rootReference.updateChildValues( [pathToUpdate: Constants.offerStatus.nonActive])
                        
                        self.rootReference.updateChildValues([lastOfferInBidStatusPath: Constants.offerStatus.nonActive])
                        self.deleteInfo(bidId: offer.bidId!)
                    
                    case Constants.appUserBidStatus.approved,Constants.appUserBidStatus.active, Constants.appUserBidStatus.complete:
                        if offer.offerStatus.rawValue != status.rawValue{
                            offer.offerStatus = Offer.status(rawValue: status.rawValue)!
                            let pathToUpdate = "/Users/\(self.appUser.firebaseId)/Bid/\(offer.bidId!)/offer/\(Constants.offer.offerStatus)"
                             self.rootReference.updateChildValues( [pathToUpdate: status.rawValue])
                        }
                        self.completion(offer: offer, browseCell: nil)
                    default:
                        //less than five minutes or if is active or completed it should procceed to acceptViewController
                        
                        self.completion(offer: offer, browseCell: nil)
                    }
                    
                })
            }else{
                self.completion(offer: offer, browseCell: nil)
            }
            
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    
    //we use this function to erase the data when there is no response.
    func deleteInfo(bidId:String){
        rootReference.child("bidIdStatus/\(bidId)").observeSingleEvent(of: .value, with:{ (snapshot) in
            guard let dictionary = snapshot.value as? [String: Any] else{
                return
            }
        
            guard let authorOfTheBid = dictionary[Constants.publicBidInfo.authorOfTheBid] as? String else{
                return
            }
            
            guard let otherUser = dictionary[Constants.publicBidInfo.otherUser] as? String else{
                return
            }
            
            
            //if the author of the bid is not the user the we erase the path to my bids otherwise is already updated
            if authorOfTheBid != self.appUser.firebaseId {
                let pathToMyBids = "/Users/\(self.appUser.firebaseId)/Bid/\(bidId)" //set to null
                self.rootReference.updateChildValues([pathToMyBids: NSNull()])
            }
            
            let pathForCounterOffer = "/counterOffer/\(authorOfTheBid)/\(bidId)"//set to null
            //set to Null
            let pathForCounterOfferOther = "/counterOffer/\(otherUser)/\(bidId)"//set to null
            self.rootReference.updateChildValues([pathForCounterOffer: NSNull()])
            self.rootReference.updateChildValues([pathForCounterOfferOther:NSNull()])
            
        })
    }

    
    func completion(offer: Offer, browseCell: BrowseCell?){
        
        let acceptOfferViewController = storyboard?.instantiateViewController(withIdentifier: "acceptOfferViewController") as! AcceptOfferViewController
        //we make the offer the default offer in acceptedOfferViewController and only changeit to the transpose if need it.
        acceptOfferViewController.offer = offer

        switch currentTable{
        case .browseOffers:
            
            acceptOfferViewController.currentStatus = .acceptOffer
            DispatchQueue.main.async{
                self.navigationController?.pushViewController(acceptOfferViewController, animated: true)
            }
            
        case .myBids:
            
            switch offer.offerStatus.rawValue{
            case Constants.offerStatus.nonActive:
                
                //we share the cell to the media
                if let imageView = browseCell?.asImage(){
                    let controller = UIActivityViewController(activityItems: [imageView], applicationActivities: nil)
                    
                    if let wPPC = controller.popoverPresentationController {
                        wPPC.sourceView = view
                        wPPC.sourceRect = view.frame
                    }
                    
                    DispatchQueue.main.async {
                        self.present(controller, animated: true, completion: nil)
                    }
                }else{
                    return
                }
               
            case Constants.offerStatus.active, Constants.offerStatus.approved, Constants.offerStatus.halfComplete:
                // if the offer is active we need to check if he is the user is the creator of the offer and acct accordingly. If the current user is the creator he needs to confirm the activation made by another client, in this case there is a transpose offer. Otherwise if he is not the creator he is wating for confirmation by the creator. In that case there is not transpose offer.
                
                //we check if the user is the creator of the bid
                if offer.firebaseId == self.appUser.firebaseId{
                    getOffers.getTransposeAcceptedOffer(path: "transposeOfacceptedOffer/\(offer.firebaseId)/\(offer.bidId!)"){
                        
                        // tere should be a transpose offer if the user is the creator of the bid
                        if let transposeOffer = self.getOffers.transposeOffer{
                            transposeOffer.bidId = offer.bidId!
                            transposeOffer.offerStatus = offer.offerStatus
                            acceptOfferViewController.offer = transposeOffer
                            switch transposeOffer.offerStatus.rawValue{
                            case Constants.offerStatus.active:
                                //we are here if the user is the creator and the offer has been accepted, then we need action for confirmation
                                acceptOfferViewController.currentStatus = .offerAcceptedNeedConfirmation
                            case Constants.offerStatus.approved:
                                acceptOfferViewController.currentStatus = .offerConfirmed
                            default:
                                print("default")
                            }
                            
                           
                            DispatchQueue.main.async {
                                self.navigationController?.pushViewController(acceptOfferViewController, animated: true)
                            }
                            
                        }
                    }
                }else{
                    
                    //if he is not the creator of the bid we present different status con the accept view Controller
                    switch offer.offerStatus.rawValue{
                    case Constants.offerStatus.active:
                        //we are here if the user is not the creator and the offer has been accepted, then we need to wait for confirmationn and is not our action
                        acceptOfferViewController.currentStatus = .waitingForConfirmation
                    case Constants.offerStatus.approved:
                        acceptOfferViewController.currentStatus = .offerConfirmed
                    default:
                        print("default")
                    }
                    
                    DispatchQueue.main.async {
                        self.navigationController?.pushViewController(acceptOfferViewController, animated: true)
                    }
                    
                }
                
                print("active")
            case Constants.offerStatus.counterOffer, Constants.offerStatus.counterOfferApproved:
                //if is a counteroffer
                getOffers.getCounterOffer(path: "counterOffer/\(appUser.firebaseId)/\(offer.bidId!)"){
                    
                    
                    if let counteroffer = self.getOffers.counteroffer{
                        
                        if counteroffer.firebaseId == self.appUser.firebaseId{
                            
                            
                            counteroffer.offerStatus = offer.offerStatus
                            switch counteroffer.offerStatus.rawValue{
                            case Constants.offerStatus.counterOffer:
                                //The user is the creator of the counteroffer(countercounteroffer in fact) thus should be waiting for confirmation
                                acceptOfferViewController.reverseLabels = true
                                acceptOfferViewController.currentStatus = .waitingForConfirmation
                                DispatchQueue.main.async {
                                    self.navigationController?.pushViewController(acceptOfferViewController, animated: true)
                                }
                                
                            case Constants.offerStatus.counterOfferApproved:
                                //The user is the creator of the counteroffer(countercounteroffer in fact) the counteroffer has been approved
                                acceptOfferViewController.currentStatus = .offerConfirmed
                                DispatchQueue.main.async {
                                    self.navigationController?.pushViewController(acceptOfferViewController, animated: true)
                                }
                                
                            default:
                                print("how did we get here?")
                            }
                            
                            
                        }else{
                            counteroffer.bidId = offer.bidId!
                            counteroffer.offerStatus = offer.offerStatus
                            acceptOfferViewController.offer = counteroffer
                            switch counteroffer.offerStatus.rawValue{
                            case Constants.offerStatus.counterOffer:
                                //we are here if the user is not the creator of the counteroffer, then we need action for confirmation, rejection or counteroffer
                                acceptOfferViewController.currentStatus = .counterOfferConfirmation
                            case Constants.offerStatus.counterOfferApproved:
                                acceptOfferViewController.currentStatus = .offerConfirmed
                            default:
                                print("default")
                            }
                            
                            DispatchQueue.main.async {
                                self.navigationController?.pushViewController(acceptOfferViewController, animated: true)
                            }
                        }
                    }else{
                        
                        //The user is the creator of the counteroffer, and has not received any counteroffers. Then there is no need to read offres from the counteroffers the user reads from its bids
                        switch offer.offerStatus.rawValue{
                        case Constants.offerStatus.counterOffer:
                            //The user is the creator of the counteroffer(countercounteroffer in fact) thus should be waiting for confirmation
                            acceptOfferViewController.currentStatus = .waitingForConfirmation
                            DispatchQueue.main.async {
                                self.navigationController?.pushViewController(acceptOfferViewController, animated: true)
                            }
                            
                        case Constants.offerStatus.counterOfferApproved:
                            //The user is the creator of the counteroffer(countercounteroffer in fact) the counteroffer has been approved
                            acceptOfferViewController.currentStatus = .offerConfirmed
                            DispatchQueue.main.async {
                                self.navigationController?.pushViewController(acceptOfferViewController, animated: true)
                            }
                            
                        default:
                            print("how did we get here?")
                        }
                    }
                }
                
                print("counterOffer")
            case Constants.offerStatus.counterOfferApproved:
                // in the case it has been approved
                
                print("approved")
            case Constants.offerStatus.complete:
                print("complete")
            default:
                print("I do not know why is complaining if I do not have this default")
            }
            
        case .myOffersInBid:
            print("get the counteroffres")
        }
    }
    
    
    
    func showExpiredAlert(){
        let alert = UIAlertController(title: NSLocalizedString("The request has expired", comment: "The request has expired"), message: NSLocalizedString("The requests that have not been approved expire after 5 min", comment: "The request that have not been approved expire after 5 min") , preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .default, handler:{ (alert) in
            self.getTheOffers()
        })
        alert.addAction(action)
        present(alert, animated: true, completion: nil)
    }
    
    func canNotDelete(){
        let alert = UIAlertController(title: NSLocalizedString("Can not delete", comment: "Can not delete"), message: NSLocalizedString("To Delete this offer it needs first to be rejected or finished", comment: "To Delete this offer it needs first to be rejected or finished"), preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .default, handler:{ (alert) in
            self.getTheOffers()
        })
        alert.addAction(action)
        present(alert, animated: true, completion: nil)
    }
    
    
    //we delete the bid and all the info pretending to it
    func deleteAllTheInfo(bidId: String){
        
        var bidsDictionary = appUser.bidIds
        let index = bidsDictionary.index(of: bidId)
        if let indexOfBid = index{
            bidsDictionary.remove(at: indexOfBid)
            appUser.bidIds = bidsDictionary
        }
        
        
        let pathForBidStatus = "/bidIdStatus/\(bidId)" // set to Null
        let pathForBidLocation = "/offerBidsLocation/\(bidId)" // set to Null
        let pathToMyBids = "/Users/\(self.appUser.firebaseId)/Bid/\(bidId)" // set to null
        let pathBid = "/\(bidId)"
        rootReference.updateChildValues([pathForBidStatus: NSNull(), pathForBidLocation: NSNull(), pathToMyBids: NSNull(), pathBid: NSNull()])
        
        rootReference.child("bidIdStatus/\(bidId)").observeSingleEvent(of: .value, with:{ (snapshot) in
            guard let dictionary = snapshot.value as? [String: Any] else{
                return
            }
            
            guard let authorOfTheBid = dictionary[Constants.publicBidInfo.authorOfTheBid] as? String else{
                return
            }
            
            guard let otherUser = dictionary[Constants.publicBidInfo.otherUser] as? String else{
                return
            }
            
            self.appUser.getOtherOffer(bidId: bidId){ otherOffer in
                
                let pathForCounterOffer = "/counterOffer/\(authorOfTheBid)/\(bidId)"//set to null
                //set to Null
                let pathForCounterOfferOther = "/counterOffer/\(otherUser)/\(bidId)"
                
                if let otherOffer = otherOffer{
                    let pathForTranspose = "/transposeOfacceptedOffer/\(otherOffer.firebaseIdOther!)/\(bidId)"// set to Null
                    self.rootReference.updateChildValues([pathForBidStatus: NSNull(), pathForBidLocation: NSNull(), pathForTranspose: NSNull(), pathToMyBids: NSNull()])
                    self.rootReference.setValue([pathForCounterOffer:NSNull()])
                    self.rootReference.setValue([pathForCounterOfferOther: NSNull()])
                }else{
                    self.rootReference.setValue([pathForCounterOffer:NSNull()])
                    self.rootReference.setValue([pathForCounterOfferOther: NSNull()])
                }
                
            }
            
        })
    }

}

//GADBanner delegate methods
extension BrowseOffersViewController{
    func adViewDidReceiveAd(_ bannerView: GADBannerView) {
        print("adViewDidReceiveAd")
    }
    
    /// Tells the delegate an ad request failed.
    func adView(_ bannerView: GADBannerView,
                didFailToReceiveAdWithError error: GADRequestError) {
        print("adView:didFailToReceiveAdWithError: \(error.localizedDescription)")
    }
    
    /// Tells the delegate that a full screen view will be presented in response
    /// to the user clicking on an ad.
    func adViewWillPresentScreen(_ bannerView: GADBannerView) {
        print("adViewWillPresentScreen")
    }
    
    /// Tells the delegate that the full screen view will be dismissed.
    func adViewWillDismissScreen(_ bannerView: GADBannerView) {
        print("adViewWillDismissScreen")
    }
    
    /// Tells the delegate that the full screen view has been dismissed.
    func adViewDidDismissScreen(_ bannerView: GADBannerView) {
        print("adViewDidDismissScreen")
    }
    
    /// Tells the delegate that a user click will open another app (such as
    /// the App Store), backgrounding the current app.
    func adViewWillLeaveApplication(_ bannerView: GADBannerView) {
        print("adViewWillLeaveApplication")
    }
}

extension UIView{
    func asImage() -> UIImage {
        let renderer = UIGraphicsImageRenderer(bounds: bounds)
        return renderer.image { rendererContext in
            layer.render(in: rendererContext.cgContext)
        }
    }
}
