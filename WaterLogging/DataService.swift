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
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
         */
        let container = NSPersistentContainer(name: "WaterLogging")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.

                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()

    public func currentGoalForToday() -> Measurement<UnitVolume>? {
        guard let goalModel = self.currentGoalModelForToday() else {
            return nil
        }

        return Measurement<UnitVolume>(value: goalModel.quantity, unit: .fluidOunces)
    }

    public func setGoalForToday(_ goal: Measurement<UnitVolume>) {
        let currentGoal: Goal

        if let currentGoalModel = self.currentGoalModelForToday() {
            currentGoal = currentGoalModel
        }
        else {
            currentGoal = Goal(context: self.persistentContainer.viewContext)
        }

        currentGoal.quantity = goal.converted(to: .fluidOunces).value
        self.saveContext()
    }

    // MARK: - Core Data Saving support

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

        let fromPredicate = NSPredicate(format: "%@ >= %@", now as NSDate, dateFrom as NSDate)
        let toPredicate = NSPredicate(format: "%@ < %@", now as NSDate, dateTo as NSDate)
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
