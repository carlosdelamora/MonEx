//
//  DimmingPresentationController.swift
//  MonEx
//
//  Created by Carlos De la mora on 1/7/17.
//  Copyright © 2017 carlosdelamora. All rights reserved.
//

import UIKit

//code similar to RayWenderlich 

// we use this class in order to not remorve the presenting view controller
class DimmingPresentationController: UIPresentationController{
    
    
    lazy var dimmingView = BlackGradientView(frame: CGRect.zero)
    
    //we set this variable to false so that the presenter view controller view is not removed
    override var shouldRemovePresentersView: Bool {
        return false
    }
    
    //the animation of the presentation of the gradient
    override func presentationTransitionWillBegin() {
        dimmingView.frame = containerView!.bounds
        containerView!.insertSubview(dimmingView, at: 0)
        
        dimmingView.alpha = 0
        if let coordinator = presentedViewController.transitionCoordinator{
            coordinator.animate(alongsideTransition:{ _ in
                self.dimmingView.alpha = 1
            }, completion: nil)
        }
    }
    
    //the animation of the dismissal of the gradient
    override func dismissalTransitionWillBegin() {
        
        // the status bar is presented once the offerview is dismissed 
        if let presentingController = presentingViewController as? InquiryViewController{
            presentingController.offerViewOnScreen = false
            presentingController.setNeedsStatusBarAppearanceUpdate()
        }
        
        if let coordinator = presentedViewController.transitionCoordinator{
            coordinator.animate(alongsideTransition:{ _ in
                self.dimmingView.alpha = 1}, completion: nil)
        }
    }
}
