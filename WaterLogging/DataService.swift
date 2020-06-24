//
//  DataService.swift
//  WaterLogging
//
//  Created by Lucas Best on 6/22/20.
//  Copyright © 2020 Apple. All rights reserved.
//

import Foundation
import CoreData

final class DataService {
    struct ProgressTotals {
        let progress: Double

        let goal: Measurement<UnitVolume>
        let progressMeasurement: Measurement<UnitVolume>
    }

    static let shared = DataService()

    // Fluid Ounces - this is an arbitrary maximum based on a recommendation of about 100 fluid ounces of water per day. Make the maximimum slightly higher for over achievers.
    public let maximumDailyIntake = 150.0

    public let formatter: MeasurementFormatter

    public init() {
        self.formatter = MeasurementFormatter()

        self.formatter.unitOptions = .naturalScale
        self.formatter.unitStyle = .long
        self.formatter.numberFormatter.maximumFractionDigits = 1
    }

    // MARK: - Core Data stack

    private lazy var persistentContainer: NSPersistentContainer = {

        let container = NSPersistentContainer(name: "WaterLogging")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                /* There could definitely be better error handling here. Becuase of time constraints I'm going to leave as-is and say that this error should be surfaced to the view layer and displayed. Perhaps switching out the rootViewController for one that can display the metadata of this error. */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()

    public func currentGoalForToday() -> Measurement<UnitVolume>? {
        guard let goalModelQuantity = self.currentGoalModelForToday()?.quantity else {
            return nil
        }

        return Measurement<UnitVolume>(value: goalModelQuantity.doubleValue, unit: .fluidOunces)
    }

    public func currentProgressForToday() -> ProgressTotals? {
        guard let currentGoal = self.currentGoalModelForToday() else {
            return nil
        }

        guard let goalValue = currentGoal.quantity, let intakes = currentGoal.intakes as? Set<Intake> else {
            return nil
        }

        let progress = intakes.reduce(into: 0.0) { ($0 += $1.quantity) }

        return ProgressTotals(progress: progress / goalValue.doubleValue, goal: Measurement<UnitVolume>(value: goalValue.doubleValue, unit: .fluidOunces), progressMeasurement: Measurement<UnitVolume>(value: progress, unit: .fluidOunces))
    }

    public func setGoalForToday(_ goal: Measurement<UnitVolume>) {
        let currentGoal: Goal = self.writableGoalForToday()
        currentGoal.quantity = NSDecimalNumber(value: goal.converted(to: .fluidOunces).value)

        self.saveContext()
    }

    public func updateProgressIntakeForToday(_ progress: Measurement<UnitVolume>, completion: @escaping() -> (), failure: @escaping(Error) -> ()) {

        let goal: Goal = self.writableGoalForToday()

        let newIntake = Intake(context: self.persistentContainer.viewContext)
        newIntake.quantity = progress.value
        newIntake.goal = goal

        func complete() {
            self.saveContext()
            completion()
        }

        func saveDataToHealthKit() {
            HealthService.shared.addWaterIntake(progress, completion: { (sampleUUID) in
                newIntake.healthUUID = sampleUUID
                complete()
            })
        }

        if HealthService.shared.isAuthorizedToShareDietaryWaterData() {
            saveDataToHealthKit()
        }
        else if HealthService.shared.canRequestDietaryWaterPermissions() {
            HealthService.shared.requestDietaryWaterAuthorization(completion: { (authorized) in
                if authorized {
                    saveDataToHealthKit()
                }
                else {
                    complete()
                }
            }, failure: { (error) in
                complete()
            })
        }
        else {
            complete()
        }
    }

    // MARK: - Private

    private func writableGoalForToday() -> Goal {
        let goal: Goal

        if let todayGoal = self.currentGoalModelForToday() {
            goal = todayGoal
        }
        else {
            goal = Goal(context: self.persistentContainer.viewContext)
            goal.timestamp = Date()
        }

        return goal
    }

    private func currentGoalModelForToday() -> Goal? {
        let fetchRequest = NSFetchRequest<Goal>(entityName: "Goal")
        fetchRequest.fetchLimit = 1

        // https://stackoverflow.com/questions/40312105/core-data-predicate-filter-by-todays-date

        let now = Date()

        // Get today's beginning & end
        let dateFrom = Calendar.current.startOfDay(for: now)

        guard let dateTo = Calendar.current.date(byAdding: .day, value: 1, to: dateFrom) else {
            // Could probably handle this better as an error, but hope for the best for now.
            return nil
        }

        let fromPredicate = NSPredicate(format: "%K >= %@", #keyPath(Goal.timestamp), dateFrom as NSDate)
        let toPredicate = NSPredicate(format: "%K < %@", #keyPath(Goal.timestamp), dateTo as NSDate)
        let datePredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [fromPredicate, toPredicate])

        fetchRequest.predicate = datePredicate

        do {
            return try self.persistentContainer.viewContext.fetch(fetchRequest).first
        }
        catch {
            return nil
        }
    }

    private func saveContext () {
        let context = self.persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
}
