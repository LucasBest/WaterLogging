# Water Logging

## App Icon Attribution: 

Icons made by <a href="https://www.flaticon.com/authors/wissawa-khamsriwath" title="Wissawa Khamsriwath">Wissawa Khamsriwath</a> from <a href="https://www.flaticon.com/" title="Flaticon"> www.flaticon.com</a>

## Other Attribution:

I consulted Stack Overflow and Apple Developer documentation for 2 features within the Water Logging app 

1)  https://stackoverflow.com/questions/40312105/core-data-predicate-filter-by-todays-date
2)  https://developer.apple.com/documentation/healthkit/hksamplequery/executing_sample_queries

The first was to build a "Day" predicate and the second was to get a jumpstart on creating a query to `HKHealthStore`. Both instances are commented above the function where I drew from the above sources.

## Running the App

The Watter Logging Xcode project is ready to run the Water Logging app on the iOS Simulator. Simply choose the "Watter Loggin" scheme and an iOS Simulator in the simulator dropdown and click the "Run" button.

## Testing

I have set up one unit test and one UI test in the Water Logging testing targets. There could absolutely be more test coverage but in the interest of time I just added basic tests to show what a typical unit test and ui test could and should look like. The two tests that are there should pass when testing the target.

## Architecture

### UI

The Water Logging app is built with a `UITabBarController` with two tabs. The leading tab is used to display today's goal and progress towards that goal. The trailing tab is used for adding water intake to the daily log. Both tabs utilize modal view controllers to modify the daily goal and add to the daily log respectively.

### Persistence

The data model for the daily water intake goal and daily intake progress are stored as as `Goal` and `Intake` entity in Core Data that each have a `quantity` key. There is a one to many relationship between a `Goal` and `Intake` making it possible to total all `Intake`s for a `Goal` in order to calculate progress for a given day.

Additionally, if the user grants the relevant Health permissions, Water Logging will store water intake samples in HealthKit.

I originally considered storing the Goal data in Core Data and then Intake Progress _only_ in HealthKit. But as I progressed, I realized that limitations with permissions were causing a level of complexity that wasn't worth the tradeoff. Ultimately I decided to store everything in Core Data and then also create HealthKit samples if the user decided they were willing to grant permission for that. That does technically mean that intake data is duplicated in Core Data and HealthKit, but this tradeoff was worth it in my opinion to simplify the app structure and requirements and still provide an experience that is integrated with Health.

### App Design

The app follows a normal MVC design pattern. Views are managed by View Controllers and the model is primarily accessed through the `DataService` singleton. The `DataService` singleton manages the business logic model access including setting and modifying a daily goal and adding to the daily water intake log. Addionally, the `HealthService` singleton manages HealthKit permissions, queries, and request executions by wrapping an `HKHealthStore` object and only exposing business logic functions that the app needs.

### Model

The model mostly consists of `Measurement` objects that either represent the daily goal or the daily progress. Using `Measurement` objects keeps the app locale and format agnostic. It also leads to a straightforward use of `MeasurementFormatter` to display goal and intake information.

### Dependencies

As mentioned above the Water Logging app utilizes both Core Data and HealthKit to store and evaluate model data. Additionally I added my personally developed, open source Swift Package, UIKitPro to speed up my UI development process. This Swift Package is simply a set of exension functions that is intended to make basic UI concepts easier to impliment.

## Thanks!

### Thanks for reviewing this app. It was a pleasure to work on and I hope to discuss it further moving forward. Thanks for your time and consideration! 

### Lucas Best
