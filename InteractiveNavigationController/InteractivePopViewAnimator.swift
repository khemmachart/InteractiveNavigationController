//
//  InteractivePopViewAnimator.swift
//  InteractiveNavigationController
//
//  Created by Khemmachart Chutapetch on 11/15/2560 BE.
//  Copyright © 2560 Khemmachart Chutapetch. All rights reserved.
//

import UIKit

class InteractivePopViewAnimator: NSObject {
    weak var toViewController: UIViewController?
    var isFromViewControllerHidesNavigationBar: Bool = false
}

extension InteractivePopViewAnimator {
    enum Duration: Double {
        case interactive = 0.3
        case noneInteractive = 0.25
    }
}

extension InteractivePopViewAnimator: UIViewControllerAnimatedTransitioning {
    
    // Approximated lengths of the default animations.
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        if let isInteractive = transitionContext?.isInteractive {
            let duration = InteractivePopViewAnimator.Duration.self
            return isInteractive ? duration.interactive.rawValue : duration.noneInteractive.rawValue
        }
        return 0
    }
    
    // Restore the toViewController's transform if the animation was cancelled
    func animationEnded(_ transitionCompleted: Bool) {
        if !transitionCompleted {
            toViewController?.view.transform = CGAffineTransform.identity
        }
    }
    
    // Tries to animate a pop transition similarly to the default iOS' pop transition.
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        
        guard let toViewController = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to) else { return }
        guard let fromViewController = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from) else { return }
        
        // Parallax effect the offset matches the one used in the pop animation in iOS 7.1
        let toViewControllerXTranslation = -transitionContext.containerView.bounds.width * 0.3
        toViewController.view.frame = getToViewControllerViewFrame(toViewController: toViewController)
        toViewController.view.transform = CGAffineTransform(translationX: toViewControllerXTranslation, y: 0)
        
        // Add a shadow on the left side of the frontmost view controller
        let previousClipsToBounds = fromViewController.view.clipsToBounds
        fromViewController.view.addLeftSideShadow()
        fromViewController.view.clipsToBounds = false
        
        // Insert subviews
        let tabBarImageView = getTemporaryTabBar(from: fromViewController, to: toViewController)
        let dimmingView = getDimmingView(at: toViewController)
        if let dimmingView = dimmingView {
            toViewController.view.addSubview(dimmingView)
        }
        if let tabBarImageView = tabBarImageView {
            toViewController.view.addSubview(tabBarImageView)
        }
        transitionContext.containerView.insertSubview(toViewController.view, belowSubview: fromViewController.view)
        
        // Uses linear curve for an interactive transition, so the view follows the finger.
        // Otherwise, uses a navigation transition curve.
        let curveOption: UIViewAnimationOptions = transitionContext.isInteractive ? .curveLinear : .curveEaseInOut
        UIView.animate(withDuration: transitionDuration(using: transitionContext), delay: 0, options: [curveOption], animations: {
            
            // Animate the previous and present views
            toViewController.view.transform = CGAffineTransform.identity
            fromViewController.view.transform = CGAffineTransform(translationX: toViewController.view.frame.width, y: 0)
            dimmingView?.alpha = 0
            
        }, completion: { _ in
            
            // Remove the subviews and restore view to the normal state
            dimmingView?.removeFromSuperview()
            tabBarImageView?.removeFromSuperview()
            
            fromViewController.view.transform = CGAffineTransform.identity
            fromViewController.view.clipsToBounds = previousClipsToBounds
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            
            if toViewController.tabBarController?.tabBar.alpha == 0 {
                toViewController.tabBarController?.tabBar.alpha = 1
            }
        })
        
        self.toViewController = toViewController
    }
}

// MARK: - Utils

extension InteractivePopViewAnimator {
    
    private func isTabBarWillAppear(
        from fromViewController: UIViewController,
        to toViewController: UIViewController) -> Bool {
        
        let isToViewControllerHidesTabBar = isTabBarHidden(at: toViewController)
        let isFromViewControllerHidesTabBar = isTabBarHidden(at: fromViewController)
        
        return !isToViewControllerHidesTabBar && isFromViewControllerHidesTabBar
    }
    
    private func getTemporaryTabBar(
        from fromViewController: UIViewController,
        to toViewController: UIViewController) -> UIImageView? {
        
        // FIXED: The hidesBottomBarWhenPushed not animated properly.
        // This block gonna be executed only when the tabbat from present view controller is hidden
        // And the previous view controller (the view controller behide, toViewController) is shown
        if isTabBarWillAppear(from: fromViewController, to: toViewController) {
            let tabBarImageView = getTabBarImageView(at: toViewController)
            
            // FIXED: UITableViewController position issue
            if let toTableViewController = toViewController as? UITableViewController {
                let tabBarRect = getTabBarFrame(from: toViewController)
                let yPosition = toTableViewController.tableView.contentOffset.y + toTableViewController.view.frame.height - tabBarRect.size.height
                tabBarImageView.frame = CGRect(x: 0, y: yPosition - tabBarRect.size.height,
                                               width: tabBarRect.size.width, height: tabBarRect.size.height)
            }
            
            // FIXED: We have to use alpha instead of hidden.
            // Hidden tabBar might effect to the main view frame and the tabBar background color
            toViewController.tabBarController?.tabBar.alpha = 0
            
            return tabBarImageView
        }
        return nil
    }
    
    private func getTabBarImageView(at toViewController: UIViewController) -> UIImageView {
        let tabBarImageView = UIImageView(frame: getTabBarFrame(from: toViewController))
        tabBarImageView.image = getScreenshot(from: toViewController.tabBarController?.tabBar)
        tabBarImageView.addSubview(getSeparatorView(from: toViewController))
        return tabBarImageView
    }
    
    private func getTabBarFrame(from toViewController: UIViewController) -> CGRect {
        guard let toTabBarController = toViewController.tabBarController else { return CGRect.zero }
        
        let viewFrame = toViewController.view.frame
        let tabBarSize = toTabBarController.tabBar.bounds
        let navigationBarHeight: CGFloat = 64
        
        if isFromViewControllerHidesNavigationBar && !isTabBarHidden(at: toViewController) {
            return CGRect(
                origin: CGPoint(x: 0, y: viewFrame.height - 49),
                size: CGSize(width: tabBarSize.width, height: tabBarSize.height))
        } else if isFromViewControllerHidesNavigationBar && toViewController.edgesForExtendedLayout != .bottom {
            return CGRect(
                origin: CGPoint(x: 0, y: viewFrame.height - navigationBarHeight),
                size: CGSize(width: tabBarSize.width, height: tabBarSize.height))
        } else if toViewController.edgesForExtendedLayout == .bottom {
            return CGRect(
                origin: CGPoint(x: 0, y: viewFrame.height - tabBarSize.height),
                size: CGSize(width: tabBarSize.width, height: tabBarSize.height))
        } else {
            return CGRect(
                origin: CGPoint(x: 0, y: viewFrame.height),
                size: CGSize(width: tabBarSize.width, height: tabBarSize.height))
        }
    }
    
    private func getToViewControllerViewFrame(toViewController: UIViewController) -> CGRect {
        let frame = toViewController.view.frame
        let edgesForExtendedTopLayout = toViewController.edgesForExtendedLayout == .top
        let edgesForExtendedBottomLayout = toViewController.edgesForExtendedLayout == .bottom
        let isToViewControllerHidesNavigationBar = toViewController.navigationController?.isNavigationBarHidden ?? false
        
        if isFromViewControllerHidesNavigationBar && !isToViewControllerHidesNavigationBar {
            if !isTabBarHidden(at: toViewController) && !edgesForExtendedTopLayout && !edgesForExtendedBottomLayout {
                return CGRect(x: 0, y: 0, width: frame.width, height: frame.height)
            } else if !edgesForExtendedTopLayout && !edgesForExtendedBottomLayout {
                return CGRect(x: 0, y: 64, width: frame.width, height: frame.height - 64)
            } else if !edgesForExtendedTopLayout {
                return CGRect(x: 0, y: 64, width: frame.width, height: frame.height - 49)
            } else if !edgesForExtendedBottomLayout {
                return CGRect(x: 0, y: 64, width: frame.width, height: frame.height - 64)
            }
        } else if isFromViewControllerHidesNavigationBar {
            if !isTabBarHidden(at: toViewController) && !edgesForExtendedTopLayout && !edgesForExtendedBottomLayout {
                return CGRect(x: 0, y: 0, width: frame.width, height: frame.height)
            } else if !edgesForExtendedTopLayout && !edgesForExtendedBottomLayout {
                return CGRect(x: 0, y: 0, width: frame.width, height: frame.height)
            } else if !edgesForExtendedTopLayout {
                return CGRect(x: 0, y: 64, width: frame.width, height: frame.height - 49 - 64)
            } else if !edgesForExtendedBottomLayout {
                return CGRect(x: 0, y: 64, width: frame.width, height: frame.height - 64)
            }
        } else {
            if !isTabBarHidden(at: toViewController) && !edgesForExtendedTopLayout && !edgesForExtendedBottomLayout {
                return CGRect(x: 0, y: 0, width: frame.width, height: frame.height - 49)
            } else if !edgesForExtendedTopLayout && !edgesForExtendedBottomLayout {
                return CGRect(x: 0, y: 64, width: frame.width, height: frame.height)
            } else if !edgesForExtendedTopLayout {
                return CGRect(x: 0, y: 64, width: frame.width, height: frame.height - 49)
            } else if !edgesForExtendedBottomLayout {
                return CGRect(x: 0, y: 64, width: frame.width, height: frame.height)
            }
        }
        return frame
    }
    
    private func getSeparatorView(from toViewController: UIViewController) -> UIView {
        let width = getTabBarFrame(from: toViewController).width
        let height: CGFloat = 1
        let lineViewFrame = CGRect(x: 0, y: -height, width: width, height: height)
        let lineView = UIView(frame: lineViewFrame)
        lineView.backgroundColor = UIColor(red: 194/255, green: 194/255, blue: 194/255, alpha: 1)
        return lineView
    }
    
    // In the default transition the view controller below is a little dimmer than the frontmost one
    private func getDimmingView(at toViewController: UIViewController) -> UIView? {
        let dimmingView = UIView(frame: toViewController.view.bounds)
        dimmingView.backgroundColor = UIColor(white: 0.0, alpha: 0.25)
        return dimmingView
    }
    
    private func getScreenshot(from view: UIView?) -> UIImage? {
        if let view = view {
            UIGraphicsBeginImageContext(view.frame.size)
            view.layer.render(in: UIGraphicsGetCurrentContext()!)
            let image = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            return image
        }
        return nil
    }
    
    private func isTabBarHidden(at viewController: UIViewController) -> Bool {
        if let tabBarController = viewController.tabBarController {
            return tabBarController.tabBar.isHidden || viewController.hidesBottomBarWhenPushed
        }
        return true
    }
}
