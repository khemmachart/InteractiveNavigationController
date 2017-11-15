//
//  ViewController.swift
//  InteractiveNavigationController
//
//  Created by Khemmachart Chutapetch on 11/15/2560 BE.
//  Copyright © 2560 Khemmachart Chutapetch. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "\(navigationController?.viewControllers.count ?? 0)"
    }

    override func viewWillAppear(_ animated: Bool) {
        if (navigationController?.viewControllers.count ?? 0) > 3 {
            navigationController?.setNavigationBarHidden(true, animated: true)
        } else {
            navigationController?.setNavigationBarHidden(false, animated: true)
        }
    }
}
