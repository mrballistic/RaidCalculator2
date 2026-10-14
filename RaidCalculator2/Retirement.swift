//
//  Retirement.swift
//  RaidCalculator2
//
//  RAID Calc2 leaves the App Store on December 31, 2026, in favour of
//  RAID Calculator. Everything the notice says comes from here.
//

import Foundation

enum Retirement {
    enum Phase: Equatable {
        /// Still on sale; the notice gives the date.
        case retiring
        /// Off sale; the app still runs on devices that have it.
        case retired
    }

    /// RAID Calculator's App Store ID and page.
    static let appStoreID = 395601653
    static let storeURL = URL(string: "https://apps.apple.com/app/id395601653")!

    /// Set once the first-launch notice has been dismissed.
    static let seenKey = "legacy.hasSeenRetirementNotice"

    /// The last day on sale is a Gregorian date in the user's own time zone,
    /// whatever calendar their device uses.
    private static func gregorian(_ timeZone: TimeZone) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return calendar
    }

    static func phase(now: Date, timeZone: TimeZone = .current) -> Phase {
        let firstDayOff = gregorian(timeZone).date(from: DateComponents(year: 2027, month: 1, day: 1))!
        return now < firstDayOff ? .retiring : .retired
    }

    /// “December 31, 2026”, in the user's language and calendar.
    static func lastDayText(locale: Locale = .current, timeZone: TimeZone = .current) -> String {
        // Midday, so no time zone can push the day either side of the 31st.
        let lastDay = gregorian(timeZone).date(from: DateComponents(year: 2026, month: 12, day: 31, hour: 12))!
        let style = Date.FormatStyle(date: .long, time: .omitted, locale: locale, calendar: locale.calendar, timeZone: timeZone)
        return lastDay.formatted(style)
    }

    /// The current date. Debug builds take `-legacy.now yyyy-MM-dd` so UI
    /// tests and screenshots can show the copy from after the date.
    static func now(defaults: UserDefaults = .standard) -> Date {
        #if DEBUG
        if let override = defaults.string(forKey: "legacy.now"),
           let date = try? Date(override, strategy: .iso8601.year().month().day()) {
            return date
        }
        #endif
        return .now
    }

    static func body(_ phase: Phase, dateText: String = lastDayText()) -> String {
        switch phase {
        case .retiring: String(format: "retirement_body_retiring".localized(), dateText)
        case .retired: "retirement_body_retired".localized()
        }
    }

    static func bannerTitle(_ phase: Phase, dateText: String = lastDayText()) -> String {
        switch phase {
        case .retiring: String(format: "retirement_banner_retiring".localized(), dateText)
        case .retired: "retirement_banner_retired".localized()
        }
    }
}
