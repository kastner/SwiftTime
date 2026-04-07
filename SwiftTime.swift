import AppKit
import Foundation
import SwiftUI

@main
struct SwiftTimeApp: App {
    @StateObject private var model = ClockModel()

    var body: some Scene {
        MenuBarExtra {
            MenuContent(model: model)
        } label: {
            Image(systemName: "clock")
                .accessibilityLabel("SwiftTime")
        }
        .menuBarExtraStyle(.window)
    }
}

struct MenuContent: View {
    @ObservedObject var model: ClockModel

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let now = context.date
            let referenceDate = model.referenceDate(now: now)
            let localLocation = model.localLocation

            VStack(alignment: .leading, spacing: 16) {
                headerSection(referenceDate: referenceDate, now: now, localLocation: localLocation)

                Divider()

                locationsSection(referenceDate: referenceDate, now: now)

                Divider()

                HStack(spacing: 10) {
                    Button {
                        model.resetToNow()
                    } label: {
                        Label("Now", systemImage: "clock.arrow.circlepath")
                    }
                    .keyboardShortcut("0")

                    Button {
                        NSApplication.shared.terminate(nil)
                    } label: {
                        Label("Quit", systemImage: "xmark.circle")
                    }
                    .keyboardShortcut("q")
                }
                .buttonStyle(.bordered)
            }
            .frame(width: 430)
            .padding(16)
        }
    }

    @ViewBuilder
    private func headerSection(referenceDate: Date, now: Date, localLocation: ClockLocation) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text("Local Time")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                Spacer()

                HourPickerButton(location: localLocation, now: now, model: model)
            }

            Text(model.timeString12(for: referenceDate, in: localLocation.timeZone))
                .font(.system(size: 31, weight: .semibold, design: .rounded))
                .foregroundStyle(.primary)

            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text(model.timeString24(for: referenceDate, in: localLocation.timeZone))
                    .font(.system(size: 16, weight: .medium, design: .monospaced))
                    .foregroundStyle(.primary)

                Text(localLocation.zoneSummary(for: referenceDate))
                    .font(.callout.weight(.medium))
                    .foregroundStyle(.secondary)

                Text(localLocation.detailText)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            Text(model.referenceSummary(now: now))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private func locationsSection(referenceDate: Date, now: Date) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("World Clocks")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            ForEach(model.locations) { location in
                ClockRow(
                    location: location,
                    referenceDate: referenceDate,
                    now: now,
                    model: model
                )
            }
        }
    }
}

private struct HourPickerButton: View {
    let location: ClockLocation
    let now: Date
    @ObservedObject var model: ClockModel

    var body: some View {
        Menu {
            ForEach(0..<24, id: \.self) { hour in
                Button(model.hourMenuLabel(hour: hour)) {
                    model.pinToHour(hour, in: location, now: now)
                }
            }
        } label: {
            Label("Set Hour", systemImage: "slider.horizontal.3")
                .labelStyle(.titleAndIcon)
        }
        .menuStyle(.borderlessButton)
        .fixedSize()
    }
}

private struct ClockRow: View {
    let location: ClockLocation
    let referenceDate: Date
    let now: Date
    @ObservedObject var model: ClockModel

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 8) {
                    Text(location.name)
                        .font(.body.weight(.medium))
                        .foregroundStyle(.primary)

                    Text(location.shortZoneLabel(for: referenceDate))
                        .font(.caption.weight(.medium))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.secondary.opacity(0.12), in: Capsule())
                        .foregroundStyle(.secondary)

                    Text(location.utcOffsetLabel(for: referenceDate))
                        .font(.caption.weight(.medium))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.secondary.opacity(0.12), in: Capsule())
                        .foregroundStyle(.secondary)

                    Text(model.relativeDayLabel(for: referenceDate, in: location.timeZone))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Text(model.timeString12(for: referenceDate, in: location.timeZone))
                    .font(.system(.title3, design: .rounded, weight: .semibold))
                    .foregroundStyle(.primary)

                Text(model.timeString24(for: referenceDate, in: location.timeZone))
                    .font(.system(.callout, design: .monospaced))
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)

            HourPickerButton(location: location, now: now, model: model)
        }
        .padding(.vertical, 2)
    }
}

@MainActor
final class ClockModel: ObservableObject {
    @Published private(set) var locations: [ClockLocation]
    @Published private var pinnedDate: Date?

    let localLocation: ClockLocation

    init() {
        let localTimeZone = TimeZone.autoupdatingCurrent
        localLocation = ClockLocation(
            id: localTimeZone.identifier,
            name: "Here",
            timeZone: localTimeZone,
            referenceIdentifier: localTimeZone.identifier
        )

        locations = [
            ClockLocation(id: "UTC", name: "UTC", timeZone: .gmt, referenceIdentifier: "UTC"),
            ClockLocation(id: "America/Los_Angeles", name: "San Francisco", timeZone: TimeZone(identifier: "America/Los_Angeles")!, referenceIdentifier: "America/Los_Angeles"),
            ClockLocation(id: "Asia/Kolkata", name: "Mumbai", timeZone: TimeZone(identifier: "Asia/Kolkata")!, referenceIdentifier: "Asia/Kolkata"),
            ClockLocation(id: "Asia/Shanghai", name: "China Standard Time", timeZone: TimeZone(identifier: "Asia/Shanghai")!, referenceIdentifier: "Asia/Shanghai"),
            ClockLocation(id: "Europe/Berlin", name: "Germany", timeZone: TimeZone(identifier: "Europe/Berlin")!, referenceIdentifier: "Europe/Berlin")
        ]
    }

    func referenceDate(now: Date) -> Date {
        if let pinnedDate {
            return pinnedDate
        }

        return now
    }

    func resetToNow() {
        pinnedDate = nil
    }

    func pinToHour(_ hour: Int, in location: ClockLocation, now: Date) {
        let currentReference = referenceDate(now: now)
        let calendar = zonedCalendar(timeZone: location.timeZone)
        var components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: currentReference)
        components.hour = hour
        components.minute = 0
        components.second = 0

        if let pinned = calendar.date(from: components) {
            pinnedDate = pinned
        }
    }

    func referenceSummary(now: Date) -> String {
        if let pinnedDate {
            let zoneLabel = localLocation.shortZoneLabel(for: pinnedDate)
            return "Pinned to \(timeString12(for: pinnedDate, in: localLocation.timeZone)) \(zoneLabel)"
        }

        return "Live local time"
    }

    func timeString12(for date: Date, in timeZone: TimeZone) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale.autoupdatingCurrent
        formatter.timeZone = timeZone
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }

    func timeString24(for date: Date, in timeZone: TimeZone) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = timeZone
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }

    func relativeDayLabel(for date: Date, in timeZone: TimeZone) -> String {
        let localDay = semanticDay(for: date, in: localLocation.timeZone)
        let targetDay = semanticDay(for: date, in: timeZone)
        let utcCalendar = zonedCalendar(timeZone: .gmt)
        let days = utcCalendar.dateComponents([.day], from: localDay, to: targetDay).day ?? 0

        switch days {
        case ..<(-1):
            return targetDay.formatted(.dateTime.weekday(.abbreviated))
        case -1:
            return "Yesterday"
        case 0:
            return "Today"
        case 1:
            return "Tomorrow"
        default:
            return targetDay.formatted(.dateTime.weekday(.abbreviated))
        }
    }

    func hourMenuLabel(hour: Int) -> String {
        let normalizedHour = ((hour % 24) + 24) % 24
        let period = normalizedHour < 12 ? "AM" : "PM"
        let twelveHour = normalizedHour % 12 == 0 ? 12 : normalizedHour % 12
        return "\(twelveHour) \(period)"
    }

    private func zonedCalendar(timeZone: TimeZone) -> Calendar {
        var calendar = Calendar.autoupdatingCurrent
        calendar.timeZone = timeZone
        return calendar
    }

    private func semanticDay(for date: Date, in timeZone: TimeZone) -> Date {
        let sourceCalendar = zonedCalendar(timeZone: timeZone)
        let components = sourceCalendar.dateComponents([.year, .month, .day], from: date)
        let utcCalendar = zonedCalendar(timeZone: .gmt)
        return utcCalendar.date(from: components) ?? date
    }
}

struct ClockLocation: Identifiable {
    let id: String
    let name: String
    let timeZone: TimeZone
    let referenceIdentifier: String

    var detailText: String {
        referenceIdentifier.replacingOccurrences(of: "_", with: " ")
    }

    func shortZoneLabel(for date: Date) -> String {
        switch referenceIdentifier {
        case "UTC":
            return "UTC"
        case "Asia/Kolkata":
            return "IST"
        default:
            return timeZone.abbreviation(for: date) ?? referenceIdentifier
        }
    }

    func utcOffsetLabel(for date: Date) -> String {
        let seconds = timeZone.secondsFromGMT(for: date)
        let totalMinutes = seconds / 60
        let sign = totalMinutes >= 0 ? "+" : "-"
        let absoluteMinutes = abs(totalMinutes)
        let hours = absoluteMinutes / 60
        let minutes = absoluteMinutes % 60

        if minutes == 0 {
            return "UTC\(sign)\(hours)"
        }

        return String(format: "UTC%@%d:%02d", sign, hours, minutes)
    }

    func zoneSummary(for date: Date) -> String {
        "\(shortZoneLabel(for: date)) \(utcOffsetLabel(for: date))"
    }
}
