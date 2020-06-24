//
//  AlertPresenter.swift
//  WaterLogging
//
//  Created by Lucas Best on 6/23/20.
//  Copyright © 2020 Apple. All rights reserved.
//

import UIKit

protocol AlertPresenter {
    func presentAlertWithTitle(_ title: String?, message: String?, completion: (() -> ())?)
}

extension AlertPresenter where Self: UIViewController {
    func presentAlertWithTitle(_ title: String?, message: String?, completion: (() -> ())? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)

        let okAction = UIAlertAction(title: NSLocalizedString("OK", comment: "OK"), style: .default, handler: { (_) in
            completion?()
        })

        alert.addAction(okAction)

        self.present(alert, animated: true)
    }
}

