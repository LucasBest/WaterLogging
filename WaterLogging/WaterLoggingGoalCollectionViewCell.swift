//
//  WaterLoggingGoalCollectionViewCell.swift
//  WaterLogging
//
//  Created by Lucas Best on 6/22/20.
//  Copyright © 2020 Apple. All rights reserved.
//

import UIKit

final class WaterLoggingGoalCollectionViewCell: UICollectionViewCell {

    @IBOutlet private(set) var goalLabel: UILabel!
    @IBOutlet private(set) var addGoalParentView: UIView!

    // MARK: - Public

    public func setGoal(_ goal: Measurement<UnitVolume>?) {
        if let realGoal = goal {
            self.addGoalParentView.isHidden = true
            self.goalLabel.isHidden = false

            self.goalLabel.text = String(format: NSLocalizedString("Intake Goal: %@", comment: "Title format for water intake goal."), DataService.shared.formatter.string(from: realGoal))
        }
        else {
            self.addGoalParentView.isHidden = false
            self.goalLabel.isHidden = true
        }
    }
}
