import UIKit
import WordPressShared

/// Defines a single row in the unified about screen.
///
struct AboutItem {
    let title: String
    let subtitle: String?
    let cellStyle: AboutItemCellStyle
    let eventButton: UnifiedAboutEvent.Button?
    let action: (() -> Void)?

    init(title: String, subtitle: String? = nil, cellStyle: AboutItemCellStyle = .default, eventButton: UnifiedAboutEvent.Button?, action: (() -> Void)? = nil) {
        self.title = title
        self.subtitle = subtitle
        self.cellStyle = cellStyle
        self.eventButton = eventButton
        self.action = action
    }

    func makeCell() -> UITableViewCell {
        switch cellStyle {
        case .default:
            return UITableViewCell(style: .default, reuseIdentifier: cellStyle.rawValue)
        case .value1:
            return UITableViewCell(style: .value1, reuseIdentifier: cellStyle.rawValue)
        case .subtitle:
            return UITableViewCell(style: .subtitle, reuseIdentifier: cellStyle.rawValue)
        case .appLogos:
            return AutomatticAppLogosCell()
        }
    }

    var cellHeight: CGFloat {
        switch cellStyle {
        case .appLogos:
            return AutomatticAppLogosCell.Metrics.cellHeight
        default:
            return UITableView.automaticDimension
        }
    }

    var cellAccessoryType: UITableViewCell.AccessoryType {
        switch cellStyle {
        case .appLogos:
            return .none
        default:
            return .disclosureIndicator
        }
    }

    var cellSelectionStyle: UITableViewCell.SelectionStyle {
        switch cellStyle {
        case .appLogos:
            return .none
        default:
            return .default
        }
    }

    enum AboutItemCellStyle: String {
        // Displays only a title
        case `default`
        // Displays a title on the leading side and a secondary value on the trailing side
        case value1
        // Displays a title with a smaller subtitle below
        case subtitle
        // Displays the custom app logos cell
        case appLogos
    }
}

class UnifiedAboutViewController: UIViewController, OrientationLimited {
    static let sections: [[AboutItem]] = [
        [
            AboutItem(title: "Rate Us", eventButton: .rateUs),
            AboutItem(title: "Share with Friends", eventButton: .share),
            AboutItem(title: "Twitter", cellStyle: .value1, eventButton: .twitter)
        ],
        [
            AboutItem(title: "Legal and More", eventButton: .legal)
        ],
        [
            AboutItem(title: "Automattic Family", eventButton: .automatticFamily),
            AboutItem(title: "", cellStyle: .appLogos, eventButton: nil)
        ],
        [
            AboutItem(title: "Work With Us", subtitle: "Join From Anywhere", cellStyle: .subtitle, eventButton: .workWithUs)
        ]
    ]

    // MARK: - Analytics

    typealias TrackEvent = ((UnifiedAboutEvent) -> Void)
    public let trackEvent: TrackEvent = { event in
        // Part of this customization should happen in the App, so that we don't need to add analytics
        // dependencies into unified-about (and it remains tracker agnostic).
        //
        // We could decide to let the app create the tracker and pass it to the VC, or maybe
        // a simpler approach where the app can set a delegate / callback in the VC for tracking.
        //
        // I'm leaving these customizations here for now until we decide the concrete solution we want
        //
        let event = AnalyticsEvent(name: event.name, properties: event.properties)

        WPAnalytics.track(event)
    }
    
    // MARK: - Views

    private static let appLogosIndexPath = IndexPath(row: 1, section: 2)

    let headerView: UIView = {
        // These customizations are temporarily here, but if this VC is moved into a framework we'll need to move them
        // into the main App.
        let appInfo = UnifiedAboutHeaderView.AppInfo(
            icon: UIImage(named: AppIcon.currentOrDefault.imageName) ?? UIImage(),
            name: (Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String) ?? "",
            version: Bundle.main.detailedVersionNumber() ?? "")

        let fonts = UnifiedAboutHeaderView.Fonts(
            appName: WPStyleGuide.serifFontForTextStyle(.largeTitle, fontWeight: .semibold),
            appVersion: WPStyleGuide.tableviewTextFont())

        let headerView = UnifiedAboutHeaderView(appInfo: appInfo, fonts: fonts)

        // Setting the frame once is needed so that the table view header will show.
        // This seems to be a table view bug although I'm not entirely sure.
        headerView.frame.size = headerView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)

        return headerView
    }()

    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.tableHeaderView = headerView

        tableView.dataSource = self
        tableView.delegate = self

        return tableView
    }()

    private lazy var footerView: UIView = {
        let footerView = UIView()
        footerView.translatesAutoresizingMaskIntoConstraints = false
        footerView.backgroundColor = .systemGroupedBackground

        let logo = UIImageView(image: UIImage(named: Images.automatticLogo))
        logo.translatesAutoresizingMaskIntoConstraints = false
        footerView.addSubview(logo)

        NSLayoutConstraint.activate([
            logo.centerXAnchor.constraint(equalTo: footerView.centerXAnchor),
            logo.centerYAnchor.constraint(equalTo: footerView.centerYAnchor)
        ])

        return footerView
    }()

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }

    // MARK: - View lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemGroupedBackground

        view.addSubview(tableView)
        view.addSubview(footerView)

        NSLayoutConstraint.activate([
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: footerView.topAnchor),
            footerView.bottomAnchor.constraint(equalTo: view.safeBottomAnchor, constant: Metrics.footerVerticalOffset),
            footerView.heightAnchor.constraint(equalToConstant: Metrics.footerHeight),
            footerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            footerView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        tableView.reloadData()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if isBeingPresented {
            trackEvent(.screenShown)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if isBeingDismissed {
            trackEvent(.screenDismissed)
        }
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        DispatchQueue.main.asyncAfter(deadline: .now() + Constants.appLogosScrollDelay) {
            self.tableView.scrollToRow(at: UnifiedAboutViewController.appLogosIndexPath, at: .middle, animated: true)
        }
    }

    // MARK: - Constants

    enum Metrics {
        static let footerHeight: CGFloat = 58.0
        static let footerVerticalOffset: CGFloat = 20.0
    }

    enum Constants {
        static let appLogosScrollDelay: TimeInterval = 0.25
    }

    enum Images {
        static let automatticLogo = "automattic-logo"
    }
}

// MARK: - Table view data source

extension UnifiedAboutViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return Self.sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Self.sections[section].count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let section = Self.sections[indexPath.section]
        let row = section[indexPath.row]

        let cell = row.makeCell()

        cell.textLabel?.text = row.title
        cell.detailTextLabel?.text = row.subtitle
        cell.accessoryType = row.cellAccessoryType
        cell.selectionStyle = row.cellSelectionStyle

        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let section = Self.sections[indexPath.section]
        let row = section[indexPath.row]

        return row.cellHeight
    }
}

// MARK: - Table view delegate

extension UnifiedAboutViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let section = Self.sections[indexPath.section]
        let row = section[indexPath.row]

        if let eventButton = row.eventButton {
            trackEvent(.buttonPressed(button: eventButton))
        }

        row.action?()
    }
}
