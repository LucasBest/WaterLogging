//
//  HealthService.swift
//  WaterLogging
//
//  Created by Lucas Best on 6/23/20.
//  Copyright © 2020 Apple. All rights reserved.
//

import Foundation
import HealthKit

struct HealthService {
    static let shared = HealthService()

    private let healthStore = HKHealthStore()

    private let waterIntakeQuantityType = HKQuantityType.quantityType(forIdentifier: .dietaryWater)!

    func canRequestDietaryWaterPermissions() -> Bool {
        return self.healthStore.authorizationStatus(for: self.waterIntakeQuantityType) == .notDetermined
    }

    func isAuthorizedToShareDietaryWaterData() -> Bool {
        return self.healthStore.authorizationStatus(for: self.waterIntakeQuantityType) == .sharingAuthorized
    }

    func requestDietaryWaterAuthorization(completion: @escaping (Bool) -> (), failure: @escaping (Error) -> ()) {
        self.healthStore.requestAuthorization(toShare: [self.waterIntakeQuantityType], read: [self.waterIntakeQuantityType]) { (authorized, error) in
            if let realError = error {
                DispatchQueue.main.async {
                    failure(realError)
                }
            }
            else {
                DispatchQueue.main.async {
                    completion(authorized)
                }

            }
        }
    }

    func addWaterIntake(_ intake: Measurement<UnitVolume>, completion: @escaping(UUID?) -> ()) {
        guard self.isAuthorizedToShareDietaryWaterData() else {
            return
        }

        let quantity = HKQuantity(unit: .fluidOunceUS(), doubleValue: intake.converted(to: .fluidOunces).value)

        let now = Date()
        let sample = HKQuantitySample(type: self.waterIntakeQuantityType, quantity: quantity, start: now, end: now)

        self.healthStore.save(sample) { (success, error) in
            if error == nil {
                DispatchQueue.main.async {
                    completion(sample.uuid)
                }
            }
            else {
                DispatchQueue.main.async {
                    completion(nil)
                }
            }
        }
    }

    func getWaterIntakeForSamplesWithUUIDs(_ uuids: [UUID], completion: @escaping(Measurement<UnitVolume>?) -> ()) {
        let predicate = HKQuery.predicateForObjects(with: Set(uuids))

        let query = HKSampleQuery(sampleType: self.waterIntakeQuantityType, predicate: predicate, limit: 1, sortDescriptors: nil) { (query, samples, error) in
            guard error == nil else {
                DispatchQueue.main.async {
                    completion(nil)
                }

                return
            }

            guard let firstSample = samples?.first as? HKQuantitySample else {
                DispatchQueue.main.async {
                    completion(nil)
                }

                return
            }

            completion(Measurement<UnitVolume>(value: firstSample.quantity.doubleValue(for: .fluidOunceUS()), unit: .fluidOunces))
        }

        self.healthStore.execute(query)
    }
}
