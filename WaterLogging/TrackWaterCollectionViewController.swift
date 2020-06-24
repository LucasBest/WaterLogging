//
//  TrackWaterCollectionViewController.swift
//  WaterLogging
//
//

import UIKit

final class TrackWaterCollectionViewController: UICollectionViewController, GoalPickerViewControllerDelegate {

    private enum Section: Hashable, Equatable, Comparable {

        case goal(Measurement<UnitVolume>?)
        case progress(DataService.ProgressTotals)

        static func < (lhs: Self, rhs: Self) -> Bool {
            return lhs.priority() < rhs.priority()
        }

        static func == (lhs: Self, rhs: Self) -> Bool {
            return lhs.priority() == rhs.priority()
        }

        // MARK: - Hashable

        func hash(into hasher: inout Hasher) {
            hasher.combine(self.priority())
        }

        private func priority() -> UInt {
            switch self {
            case .goal:
                return 0
            case .progress:
                return 1
            }
        }
    }

    private struct Tracking {
        private var sections: Set<Section> = [Section.goal(nil)]

        func numberOfSections() -> Int {
            return self.sections.count
        }

        mutating func updateGoal(_ goal: Measurement<UnitVolume>) {
            self.sections.update(with: .goal(goal))
        }

        mutating func updateProgress(_ progress: DataService.ProgressTotals) {
            self.sections.update(with: .progress(progress))
        }

        func currentGoal() -> Measurement<UnitVolume>? {
            for section in self.sections {
                switch section {
                case .goal(let measurement):
                    return measurement
                default:
                    break
                }
            }

            return nil
        }

        func sectionAtIndex(_ index: Int) -> Section? {
            guard index >= 0, index < self.sections.count else {
                return nil
            }

            return self.sections.sorted()[index]
        }
    }

    private var tracking = Tracking()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.collectionView.collectionViewLayout = self.createLayout()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.reloadViews()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "chooseAGoal":
            let goalPickerViewController = (segue.destination as! UINavigationController).topViewController as! GoalPickerViewController
            goalPickerViewController.delegate = self
            goalPickerViewController.currentGoal = self.tracking.currentGoal()
        default:
            break
        }
    }

    // MARK: - UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return self.tracking.numberOfSections()
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // Could build this out more if necessary.
        return 1
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let section = self.tracking.sectionAtIndex(indexPath.section) else {
            /* Not an ideal solution here. Would prefer to have a placeholder cell as backup but in the interest of time, skipping that implementation. */
            return UICollectionViewCell()
        }

        switch section {
        case .goal(let goal):
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: WaterLoggingGoalCollectionViewCell.self), for: indexPath) as! WaterLoggingGoalCollectionViewCell

            cell.setGoal(goal)

            return cell
        case .progress(let progressTotals):
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: WaterLoggingProgressCollectionViewCell.self), for: indexPath) as! WaterLoggingProgressCollectionViewCell

            cell.progressLabel.text = String(format: NSLocalizedString("%@ out of %@ consumed", comment: "Format for progress of water consumed in a day"), DataService.shared.formatter.string(from: progressTotals.progressMeasurement), DataService.shared.formatter.string(from: progressTotals.goal))

            cell.progressView.progress = Float(progressTotals.progress)

            return cell
        }
    }

    // MARK: - UICollectionViewDelegate

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let section = self.tracking.sectionAtIndex(indexPath.section)

        switch section {
        case .goal:
            self.performSegue(withIdentifier: "chooseAGoal", sender: self)
        default:
            break
        }
    }

    // MARK: - GoalPickerViewControllerDelegate

    final func goalPickerViewController(_ goalPickerViewController: GoalPickerViewController, didSelectGoal goal: Measurement<UnitVolume>) {

        self.reloadViews()
        self.dismiss(animated: true)
    }

    // MARK: - Actions

    @IBAction final func unwindToTrackWaterCollectionViewController(_ segue: UIStoryboardSegue) {
        self.reloadViews()
    }

    // MARK: - Private

    private func reloadViews() {
        var reload = false

        if let realCurrentGoal = DataService.shared.currentGoalForToday() {
            self.tracking.updateGoal(realCurrentGoal)
            reload = true
        }

        if let realProgress = DataService.shared.currentProgressForToday() {
            self.tracking.updateProgress(realProgress)
            reload = true
        }

        if reload {
            self.collectionView.reloadData()
        }
    }

    private func createLayout() -> UICollectionViewCompositionalLayout {
        let layout = UICollectionViewCompositionalLayout { (sectionIndex, environment) -> NSCollectionLayoutSection? in

            let item = NSCollectionLayoutItem(layoutSize: .init(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(100.0)))

            let group = NSCollectionLayoutGroup.horizontal(layoutSize: .init(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(100.0)), subitems: [item])

            return NSCollectionLayoutSection(group: group)
        }

        return layout
    }
}

