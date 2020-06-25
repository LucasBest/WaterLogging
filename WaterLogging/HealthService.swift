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
        guard HKHealthStore.isHealthDataAvailable() else {
            return false
        }

        return self.healthStore.authorizationStatus(for: self.waterIntakeQuantityType) == .notDetermined
    }

    func isAuthorizedToShareDietaryWaterData() -> Bool {
        guard HKHealthStore.isHealthDataAvailable() else {
            return false
        }

        return self.healthStore.authorizationStatus(for: self.waterIntakeQuantityType) == .sharingAuthorized
    }

    func requestDietaryWaterAuthorization(completion: @escaping (Bool) -> (), failure: @escaping (Error) -> ()) {
        guard HKHealthStore.isHealthDataAvailable() else {
            DispatchQueue.main.async {
                completion(false)
            }
            return
        }

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

    func getWeight() {

    }

    func getWeight(completion: @escaping(Measurement<UnitMass>?) -> ()) {
        let weightType = HKQuantityType.quantityType(forIdentifier: .bodyMass)!

        func query() {
            // https://developer.apple.com/documentation/healthkit/hksamplequery/executing_sample_queries
            let sortByDate = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)

            let query = HKSampleQuery(sampleType: HKQuantityType.quantityType(forIdentifier: .bodyMass)!, predicate: nil, limit: 1, sortDescriptors: [sortByDate]) { (query, samples, error) in
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

                DispatchQueue.main.async {
                     completion(Measurement<UnitMass>(value: firstSample.quantity.doubleValue(for: .pound()), unit: .pounds))
                }
            }

            self.healthStore.execute(query)
        }

        switch self.healthStore.authorizationStatus(for: weightType) {
        case .notDetermined:
            self.healthStore.requestAuthorization(toShare: nil, read: [weightType]) { (authorized, error) in
                if error == nil && authorized {
                    query()
                }
                else {
                    DispatchQueue.main.async {
                        completion(nil)
                    }
                }
            }
        case .sharingAuthorized, .sharingDenied:
            query()
        @unknown default:
            DispatchQueue.main.async {
                completion(nil)
            }
        }
    }
}
