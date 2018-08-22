//
//  InteractiveNavigationController.swift
//  InteractiveNavigationController
//
//  Created by Khemmachart Chutapetch on 11/15/2560 BE.
//  Copyright © 2560 Khemmachart Chutapetch. All rights reserved.
//

import UIKit

/**
 * InteractiveNavigationController conforming to `UINavigationControllerDelegate` protocol that
 * allows pan back gesture to be started from anywhere on the screen (not only from the left edge).
 */
class InteractiveNavigationController: UINavigationController {
    
    private lazy var panRecognizer: UIPanGestureRecognizer = {
        let panRecognizer = InteractiveGestureRecognizer(target: self, action: #selector(handleGesture))
        panRecognizer.direction = .right
        panRecognizer.maximumNumberOfTouches = 1
        panRecognizer.delegate = self
        return panRecognizer
    }()
    
    private lazy var animator: InteractivePopViewAnimator = {
        let animator = InteractivePopViewAnimator()
        return animator
    }()
    
    private var isInteractivePopGestureRecognizerEnabled: Bool {
        if let isEnabled = interactivePopGestureRecognizer?.isEnabled {
            return isEnabled
        }
        return true
    }
    
    private var interactionController: UIPercentDrivenInteractiveTransition?
    
    // MARK: - Initialization
    
    override func awakeFromNib() {
        super.awakeFromNib()
        addGestureRecognizer()
        addNavigationControllerDelegate()
    }
    
    deinit {
        panRecognizer.removeTarget(self, action: #selector(handleGesture(recognizer:)))
        view.removeGestureRecognizer(panRecognizer)
    }
    
    // MARK: - Utils
    
    func addGestureRecognizer() {
        view.addGestureRecognizer(panRecognizer)
    }
    
    func addNavigationControllerDelegate() {
        delegate = self
    }
    
    // Enable the pan gesture when finished animation and the view controller has set interactive to be ture
    private func enabledPanGestureRecognizer(afterDuration duration: InteractivePopViewAnimator.Duration) {
        let milliseconds = Int(duration.rawValue * 1000)
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(milliseconds), execute: {
            self.panRecognizer.isEnabled = true && self.isInteractivePopGestureRecognizerEnabled
        })
    }
    
    // MARK: - UIPanGestureRecognizer
    
    @objc func handleGesture(recognizer: UIPanGestureRecognizer) {
        
        switch recognizer.state {
            
        case .began:
            if viewControllers.count > 1 {
                interactionController = UIPercentDrivenInteractiveTransition()
                interactionController?.completionCurve = .linear
                popViewController(animated: true)
            }
            
        case .changed:
            let translation = recognizer.translation(in: view)
            // Cumulative translation.x can be less than zero
            // because user can pan slightly to the right and then back to the left.
            let d = translation.x > 0 ? translation.x / view.bounds.width : 0
            interactionController?.update(d)
            
        case .ended, .cancelled:
            let widthCondition = (interactionController?.percentComplete ?? 0) > 0.5
            // let positionCondition = recognizer.location(in: view).x > 120
            // let velocityCondition = recognizer.velocity(in: view).x > 0
            
            if widthCondition {
                interactionController?.finish()
            } else {
                interactionController?.cancel()
                // When the transition is cancelled, 'navigationController:didShowViewController:animated:'
                // isn't called, so we have to maintain the gesture state here
                panRecognizer.isEnabled = false
                // Resolved the navigation bar bug by adding the duration to enabled the gesture.
                // Because swiping the view controller to fast might be caused of the bug
                enabledPanGestureRecognizer(afterDuration: .interactive)
            }
            interactionController = nil
            
        default:
            break
        }
    }
}

// MARK: - UIGestureRecognizerDelegate

extension InteractiveNavigationController: UIGestureRecognizerDelegate {
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return viewControllers.count > 1
    }
}

// MARK: - UINavigationControllerDelegate

extension InteractiveNavigationController: UINavigationControllerDelegate {
    
    func navigationController(_ navigationController: UINavigationController, animationControllerFor operation: UINavigationControllerOperation, from fromVC: UIViewController, to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        if operation == UINavigationControllerOperation.pop {
            return animator
        } else {
            return nil
        }
    }
    
    func navigationController(_ navigationController: UINavigationController, interactionControllerFor animationController: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return interactionController
    }
    
    func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
        
        // Keep the navigation bar hidden for the current view to calculate the view frame
        animator.isFromViewControllerHidesNavigationBar = isNavigationBarHidden
        
        // Handle the pan recognizer enable, with the isInteractivePopGestureRecognizerEnabled from user
        if navigationController.viewControllers.count < 2 {
            panRecognizer.isEnabled = false
        } else {
            panRecognizer.isEnabled = true && isInteractivePopGestureRecognizerEnabled
        }
    }
}
