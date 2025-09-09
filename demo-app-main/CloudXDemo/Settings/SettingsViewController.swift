//
//  SettingsViewController.swift
//  CloudXDemo
//
//  Created by bkorda on 01.03.2024.
//

import UIKit
import CloudXCore
import SwiftUI

class SettingsViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        let settingsView = UIHostingController(rootView: SettingSwiftUI())
        addChild(settingsView)
        settingsView.view.frame = self.view.bounds
        self.view.addSubview(settingsView.view)
        settingsView.didMove(toParent: self)
    }
}
