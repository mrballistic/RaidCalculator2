//
//  RetirementTests.swift
//  RaidCalculator2Tests
//

import Foundation
import Testing
@testable import RAID_Calc

@MainActor
struct RetirementTests {
    /// A wall-clock moment in a time zone, from Gregorian fields.
    private func moment(_ y: Int, _ m: Int, _ d: Int, _ h: Int, _ min: Int, in zone: String) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: zone)!
        return calendar.date(from: DateComponents(year: y, month: m, day: d, hour: h, minute: min))!
    }

    @Test(arguments: ["America/Los_Angeles", "Europe/Berlin", "Asia/Tokyo", "Pacific/Kiritimati", "Etc/GMT+12"])
    func retiringThroughTheLastLocalDay(zone: String) {
        let tz = TimeZone(identifier: zone)!
        #expect(Retirement.phase(now: moment(2026, 10, 13, 12, 0, in: zone), timeZone: tz) == .retiring)
        #expect(Retirement.phase(now: moment(2026, 12, 31, 23, 59, in: zone), timeZone: tz) == .retiring)
        #expect(Retirement.phase(now: moment(2027, 1, 1, 0, 0, in: zone), timeZone: tz) == .retired)
        #expect(Retirement.phase(now: moment(2028, 6, 1, 12, 0, in: zone), timeZone: tz) == .retired)
    }

    @Test func phaseIgnoresTheUserCalendar() {
        // The boundary is computed in Gregorian whatever the device's calendar,
        // so a Japanese- or Buddhist-calendar user switches the same day.
        let tz = TimeZone(identifier: "Asia/Tokyo")!
        #expect(Retirement.phase(now: moment(2026, 12, 31, 23, 59, in: "Asia/Tokyo"), timeZone: tz) == .retiring)
        #expect(Retirement.phase(now: moment(2027, 1, 1, 0, 1, in: "Asia/Tokyo"), timeZone: tz) == .retired)
    }

    @Test func lastDayInEnglishAndGerman() {
        let utc = TimeZone(identifier: "UTC")!
        #expect(Retirement.lastDayText(locale: Locale(identifier: "en_US"), timeZone: utc) == "December 31, 2026")
        #expect(Retirement.lastDayText(locale: Locale(identifier: "de_DE"), timeZone: utc) == "31. Dezember 2026")
    }

    @Test(arguments: ["Pacific/Kiritimati", "Etc/GMT+12", "America/Los_Angeles"])
    func dateTextIsTheLastDayEverywhere(zone: String) {
        #expect(Retirement.lastDayText(locale: Locale(identifier: "en_US"), timeZone: TimeZone(identifier: zone)!) == "December 31, 2026")
    }

    @Test func japaneseCalendarUserSeesTheSameDay() {
        let text = Retirement.lastDayText(locale: Locale(identifier: "ja_JP@calendar=japanese"), timeZone: TimeZone(identifier: "Asia/Tokyo")!)
        // 2026 is Reiwa 8.
        #expect(text.contains("令和8"), "\(text)")
        #expect(text.contains("12月31日"), "\(text)")
    }

    @Test func storeLink() {
        #expect(Retirement.appStoreID == 395601653)
        #expect(Retirement.storeURL.absoluteString == "https://apps.apple.com/app/id395601653")
    }

    @Test func copyFollowsThePhase() {
        #expect(Retirement.body(.retiring, dateText: "DAY").contains("DAY"))
        #expect(!Retirement.body(.retired, dateText: "DAY").contains("DAY"))
        #expect(Retirement.bannerTitle(.retiring, dateText: "DAY").contains("DAY"))
        #expect(!Retirement.bannerTitle(.retired, dateText: "DAY").contains("DAY"))
        #expect(Retirement.body(.retiring) != Retirement.body(.retired))
    }

    @Test func nowReadsTheDebugOverride() {
        let name = "RetirementTests"
        let defaults = UserDefaults(suiteName: name)!
        defaults.removePersistentDomain(forName: name)
        defaults.set("2027-01-02", forKey: "legacy.now")
        #expect(Retirement.phase(now: Retirement.now(defaults: defaults), timeZone: TimeZone(identifier: "UTC")!) == .retired)
        defaults.removeObject(forKey: "legacy.now")
        #expect(abs(Retirement.now(defaults: defaults).timeIntervalSinceNow) < 5)
    }
}
