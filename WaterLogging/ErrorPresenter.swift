//
//  ErrorPresenter.swift
//  WaterLogging
//
//  Created by Lucas Best on 6/23/20.
//  Copyright © 2020 Apple. All rights reserved.
//

import UIKit

protocol ErrorPresenter {
    func presentError(_ error: Error, completion: (() -> ())?)
}

extension ErrorPresenter where Self: AlertPresenter {
    func presentError(_ error: Error, completion: (() -> ())? = nil) {
        self.presentAlertWithTitle(error.localizedDescription, message: (error as NSError).localizedRecoverySuggestion, completion: completion)
    }
}
