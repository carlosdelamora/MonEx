//
//  SlideOutAnimationController.swift
//  MonEx
//
//  Created by Carlos De la mora on 1/7/17.
//  Copyright © 2017 carlosdelamora. All rights reserved.
//

import UIKit

class SlideOutAnimationController: NSObject, UIViewControllerAnimatedTransitioning{
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.3
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning){
        
        if let fromView = transitionContext.view(forKey: UITransitionContextViewKey.from){
            
            let containerView = transitionContext.containerView
            let duration = transitionDuration(using: transitionContext)
            UIView.animate(withDuration: duration, animations: {
                fromView.center.y -= containerView.bounds.size.height
                fromView.transform = CGAffineTransform(scaleX: 0.5, y:0.5)
            },completion: {finished in
                transitionContext.completeTransition(finished)
            })
        }
        
        /*guard let fromVC = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from)  as? OfferViewController else{
            return
        }
        let containerView = transitionContext.containerView
        let duration = transitionDuration(using: transitionContext)

        UIView.animateKeyframes(withDuration: duration , delay: 0.0, options: .calculationModeCubic, animations: {
            fromVC
        }, completion: { finished in
            
            transitionContext.completeTransition(finished)
        })*/

    }
}
