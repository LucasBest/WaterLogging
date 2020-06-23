//
//  GoalPickerViewController.swift
//  WaterLogging
//
//  Created by Lucas Best on 6/22/20.
//  Copyright © 2020 Apple. All rights reserved.
//

import UIKit

protocol GoalPickerViewControllerDelegate: class {
    func goalPickerViewController(_ goalPickerViewController: GoalPickerViewController, didSelectGoal goal: Measurement<UnitVolume>)
}

final class GoalPickerViewController: UIViewController {

    weak var delegate: GoalPickerViewControllerDelegate?
    var currentGoal: Measurement<UnitVolume>? {
        didSet {
            if self.isViewLoaded {
                self.refreshFromCurrentGoal()
            }
        }
    }

    @IBOutlet private(set) var healthkitBarButtonItem: UIBarButtonItem!
    @IBOutlet private(set) var healthkitExplanationParentView: UIView!

    @IBOutlet private(set) var quantityImageView: UIImageView!
    @IBOutlet private(set) var quantityLabel: UILabel!
    @IBOutlet private(set) var quantitySlider: UISlider!
    @IBOutlet private(set) var setGoalButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        self.refreshFromCurrentGoal()
    }

    // MARK: - Actions

    @IBAction final func sliderValueDidChange(_ sender: UISlider) {
        self.refreshFromMeasurement(self.currentSelection())
    }

    @IBAction final func setGoal(_ sender: UIButton) {
        let goal = self.currentSelection()
        DataService.shared.setGoalForToday(goal)

        self.delegate?.goalPickerViewController(self, didSelectGoal: goal)
    }

    // MARK: - Private

    private func refreshFromCurrentGoal() {
        if let realCurrentGoal = self.currentGoal {
            self.quantitySlider.value = Float(realCurrentGoal.value / DataService.shared.maximumDailyIntake * Double(self.quantitySlider.value))
            self.refreshFromMeasurement(realCurrentGoal)
        }
    }

    private func refreshFromMeasurement(_ measurement: Measurement<UnitVolume>) {
        self.quantityLabel.text = DataService.shared.formatter.string(from: measurement)

        switch self.quantitySlider.value {
        case 0..<0.33:
            self.quantityImageView.image = UIImage(systemName: "archivebox")
        case 0.33..<0.66:
            self.quantityImageView.image = UIImage(systemName: "archivebox.fill")
        case 0.66..<1.0:
            self.quantityImageView.image = UIImage(systemName: "arrow.up.bin")
        default:
            break
        }

        if self.setGoalButton.isHidden {
            self.setGoalButton.alpha = 0.0
            self.setGoalButton.isHidden = false

            UIView.animate(withDuration: 0.25) {
                self.setGoalButton.alpha = 1.0
            }
        }
    }

    private func currentSelection() -> Measurement<UnitVolume> {
        let selected = DataService.shared.maximumDailyIntake * Double(self.quantitySlider.value)
        return Measurement<UnitVolume>(value: selected, unit: .fluidOunces)
    }
}
