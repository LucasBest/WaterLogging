//
//  AddWaterIntakeViewController.swift
//  WaterLogging
//
//

import UIKit

final class AddWaterIntakeViewController: UIViewController, AlertPresenter, ErrorPresenter {

    @IBOutlet private(set) var quantityLabel: UILabel!
    @IBOutlet private(set) var quantityStepper: UIStepper!
    @IBOutlet private(set) var addButton: UIButton!

    private var currentQuantity = 0.0

    override func viewDidLoad() {
        super.viewDidLoad()
        self.refreshCurrentQuantity()
    }

    // MARK: - Actions

    @IBAction final func jumpStepQuantity(_ sender: UIButton) {
        let multiplier = Double(sender.tag) * 8.0

        self.updateCurrentQuantity(self.currentQuantity + multiplier)
        self.refreshCurrentQuantity()
    }

    @IBAction final func quantityStepperValueChanged(_ sender: UIStepper) {
        self.updateCurrentQuantity(sender.value)
        self.refreshCurrentQuantity()
    }

    @IBAction final func addIntake(_ sender: UIButton) {
        let measurement = self.currentMeasurement()

        DataService.shared.updateProgressIntakeForToday(measurement, completion: {
            self.presentAlertWithTitle(NSLocalizedString("Success!", comment: "Title for success when HealthKit data is saved."), message: nil) {
                self.performSegue(withIdentifier: "seeProgress", sender: measurement)
            }

            self.currentQuantity = 0
            self.refreshCurrentQuantity()
        }) { (error) in
            self.presentError(error)
        }
    }

    // MARK: - Private

    private func currentMeasurement() -> Measurement<UnitVolume> {
        return Measurement<UnitVolume>(value: self.currentQuantity, unit: .fluidOunces)
    }

    private func updateCurrentQuantity(_ newQuantity: Double) {
        self.currentQuantity = newQuantity
        self.currentQuantity = min(self.currentQuantity, DataService.shared.maximumDailyIntake)

        self.quantityStepper.value = self.currentQuantity
    }

    private func refreshCurrentQuantity() {
        let measurement = self.currentMeasurement()
        self.quantityLabel.text = DataService.shared.formatter.string(from: measurement)

        if self.currentQuantity > 0 && self.addButton.isHidden {
            self.addButton.alpha = 0.0
            self.addButton.isHidden = false

            UIView.animate(withDuration: 0.25) {
                self.addButton.alpha = 1.0
            }
        }
        else if self.currentQuantity <= 0 {
            UIView.animate(withDuration: 0.25, animations: {
                self.addButton.alpha = 0.0
            }) { (_) in
                self.addButton.isHidden = true
            }
        }
    }
}

