//
//  BounceAnimationController.swift
//  MonEx
//
//  Created by Carlos De la mora on 1/7/17.
//  Copyright © 2017 carlosdelamora. All rights reserved.
//

import UIKit

class BounceAnimationController: NSObject, UIViewControllerAnimatedTransitioning{
    
    //the time the presentation animation should take
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.4
    }
    
    //method to animate the presentation transitioning that is why we use .to
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        
        if let toViewController = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to), let toView = transitionContext.view(forKey: UITransitionContextViewKey.to){
            
            let containerView = transitionContext.containerView
            toView.frame = transitionContext.finalFrame(for: toViewController)
            containerView.addSubview(toView)
            toView.transform = CGAffineTransform(scaleX: 0.7, y: 0.7)
            
            UIView.animateKeyframes(withDuration: transitionDuration(using: transitionContext), delay: 0, options: .calculationModeCubic, animations:{
                
                UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 0.334,
                                   animations:{ toView.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)})
                
                UIView.addKeyframe(withRelativeStartTime: 0.334, relativeDuration: 0.333, animations: { toView.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)})
                
                UIView.addKeyframe(withRelativeStartTime: 0.666, relativeDuration: 0.333, animations: { toView.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)})
                
            }, completion:{ finished in
                
                transitionContext.completeTransition(finished)
            })
        }
        
    }

}
