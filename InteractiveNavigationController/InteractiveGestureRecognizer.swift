//
//  InteractiveGestureRecognizer.swift
//  InteractiveNavigationController
//
//  Created by Khemmachart Chutapetch on 11/15/2560 BE.
//  Copyright © 2560 Khemmachart Chutapetch. All rights reserved.
//

import UIKit
import UIKit.UIGestureRecognizerSubclass

class InteractiveGestureRecognizer: UIPanGestureRecognizer {
    
    var direction: InteractivePanDirection?
    var dragging: Bool = false
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesMoved(touches, with: event)
        
        guard state != .failed else { return }
        guard let expectedDirection = self.direction else { return }
        
        let velocity = self.velocity(in: view)
        
        // Check direction only on the first move
        if !dragging && !velocity.equalTo(CGPoint.zero) {
            let panDirection = getDirection(from: velocity)
            
            // Fails the gesture if the highest velocity isn't in the same direction as `direction` property.
            if panDirection != expectedDirection {
                state = .failed
            }
            
            dragging = true
        }
    }
    
    override func reset() {
        dragging = false
    }
}

extension InteractiveGestureRecognizer {
    
    // MARK: - Utils
    
    enum InteractivePanDirection {
        case up
        case left
        case down
        case right
    }
    
    fileprivate func getDirection(from velocity: CGPoint) -> InteractivePanDirection? {
        
        let velocities: [InteractivePanDirection: CGFloat] = [
            .up: -velocity.y,
            .left: -velocity.x,
            .down: velocity.y,
            .right: velocity.x
        ]
        
        // Finding the pan direction from highest velocity
        let maxValue = velocities.values.max()
        let keyStore = velocities.filter({ $0.value == maxValue }).first?.key
        
        return keyStore
    }
}
