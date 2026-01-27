//
//  HistoryViewModel.swift
//  gacha
//
//  Created by Oh Seojin on 10/29/25.
//

import Combine
import SwiftData
import SwiftUI

enum ChartType: Hashable {
    case rom
    case pain
}

class HistoryViewModel: ObservableObject {
    private var repository: RecordRepository

    @Published private(set) var allRecords: [MeasuredRecord] = []
    @Published var recentRecords: [MeasuredRecord] = []
    @Published var selectedROMDate: Date? = nil
    @Published var selectedPainDate: Date? = nil
    @Published var selectedROMIndex: Int? = nil  // 0~6 (일~토)
    @Published var selectedPainIndex: Int? = nil // 0~6 (일~토)
    @Published var currentROMWeekOffset: Int = 0
    @Published var currentPainWeekOffset: Int = 0
    @Published var isLoading: Bool = false

    init(repository: RecordRepository) {
        self.repository = repository
    }

    let calendar = Calendar.current
    
    var week: [String] {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.calendar = calendar
        formatter.dateFormat = "EEE"
        
        let today = Date()
        let weekdayIndex = calendar.component(.weekday, from: today) - 1 // 0=일, 6=토
        guard let sunday = calendar.date(byAdding: .day, value: -weekdayIndex, to: today) else {
            return ["Sun","Mon","Tue","Wed","Thu","Fri","Sat"] // fallback
        }

        return (0..<7).compactMap { i in
            if let date = calendar.date(byAdding: .day, value: i, to: sunday) {
                return formatter.string(from: date)
            } else {
                return nil
            }
        }
    }
        
    // MARK: - calculated property
    var romAverage: Int {
        guard !recentRecords.isEmpty else { return 0 }
        let sum = recentRecords.compactMap { $0.ROM }.map { Int($0) }.reduce(
            0,
            +
        )
        return sum / recentRecords.count
    }

    var dateRangeText: String {
        guard !recentRecords.isEmpty else { return "" }

        // 데이터가 1개인 경우
        if recentRecords.count == 1,
            let singleDate = recentRecords.first?.measuredDate
        {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy/M/d"
            return formatter.string(from: singleDate)
        }

        // 데이터가 2개 이상인 경우
        guard let startDate = recentRecords.first?.measuredDate,
            let endDate = recentRecords.last?.measuredDate
        else {
            return ""
        }
        return formatDateRange(startDate: startDate, endDate: endDate)
    }

    var painMin: Int {
        guard let min = recentRecords.compactMap({ $0.painLevel }).min() else {
            return 0
        }
        return min
    }

    var painMax: Int {
        guard let max = recentRecords.compactMap({ $0.painLevel }).max() else {
            return 0
        }
        return max
    }

    // MARK: - Summary Cards Data

    var totalRecordCount: Int {
        allRecords.count
    }

    /// 첫 번째 (가장 오래된) 기록 중 ROM 값이 존재하는 각도
    var firstAvailableROM: Int? {
        guard let record = allRecords.first(where: { $0.flexionAngle != nil }),
            let rom = record.flexionAngle
        else { return nil }
        return Int(rom)
    }

    /// 마지막 (가장 최근) 기록의 ROM
    /// 오늘 기록에 ROM이 없으면 이전 기록에서 가장 최근의 ROM 값을 반환
    var latestROM: Int? {
        guard
            let record = allRecords.reversed().first(where: {
                $0.flexionAngle != nil
            }),
            let rom = record.flexionAngle
        else { return nil }
        return Int(rom)
    }

    /// ROM 변화량 (최근 - 오래된)
    var romChange: Int? {
        guard let first = firstAvailableROM, let latest = latestROM else {
            return nil
        }
        return latest - first
    }

    /// ROM 변화 설명 텍스트
    var romChangeText: String {
        guard totalRecordCount > 1,
            let change = romChange,
            change != 0
        else {
            return Strings.History.cardRomSame(days: daysBetweenRecords)
        }

        if change > 0 {
            return Strings.History.cardRomBetter(
                days: daysBetweenRecords,
                degrees: abs(change)
            )
        } else {
            return Strings.History.cardRomWorse(
                days: daysBetweenRecords,
                degrees: abs(change)
            )
        }
    }

    /// ROM 서브타이틀 (최근 일주일 이내 데이터와 오늘 데이터 비교)
    var romSubtitle: String {
        // 측정 기록이 없는 경우
        guard !recentRecords.isEmpty else {
            return Strings.History.chartRomNoRecord
        }

        // 첫 측정인 경우
        guard recentRecords.count > 1,
            let todayROM = latestROM
        else {
            guard let firstROM = latestROM else {
                return Strings.History.chartRomNoRecord
            }
            return Strings.History.chartRomFirstRecord(angle: firstROM)
        }

        // 최근 일주일 이내의 최대 ROM (오늘 제외)
        let previousRecords = recentRecords.dropLast()
        guard
            let maxPreviousROM = previousRecords.compactMap({ $0.flexionAngle })
                .max()
        else {
            return Strings.History.chartRomFirstRecord(angle: todayROM)
        }

        let maxPreviousROMInt = Int(maxPreviousROM)
        let difference = abs(todayROM - maxPreviousROMInt)

        // 비교 (ROM은 클수록 좋음)
        if Double(todayROM) > maxPreviousROM {
            return Strings.History.chartRomBetter(
                improvement: difference,
                prevMax: maxPreviousROMInt
            )
        } else if Double(todayROM) == maxPreviousROM {
            return Strings.History.chartRomSame(prevMax: maxPreviousROMInt)
        } else {
            return Strings.History.chartRomWorse(
                decline: difference,
                prevMax: maxPreviousROMInt
            )
        }
    }

    /// 첫 번째와 마지막 기록 사이의 날짜 차이 (일 단위)
    var daysBetweenRecords: Int {
        guard totalRecordCount > 1,
            let firstDate = allRecords.first?.measuredDate,
            let lastDate = allRecords.last?.measuredDate
        else {
            print("📅 [daysBetweenRecords] 기록이 1개 이하: \(totalRecordCount)")
            return 0
        }

        // 각 날짜의 시작 시간을 기준으로 비교
        let firstDayStart = calendar.startOfDay(for: firstDate)
        let lastDayStart = calendar.startOfDay(for: lastDate)
        let components = calendar.dateComponents(
            [.day],
            from: firstDayStart,
            to: lastDayStart
        )
        let days = max(components.day ?? 0, 0)  // 음수 방지

        print("📅 [daysBetweenRecords] 계산:")
        print("   - 첫 기록: \(firstDate) -> \(formatShortDate(firstDate))")
        print("   - 마지막 기록: \(lastDate) -> \(formatShortDate(lastDate))")
        print("   - 첫 날 시작: \(firstDayStart)")
        print("   - 마지막 날 시작: \(lastDayStart)")
        print("   - 날짜 차이: \(days)일")

        return days
    }

    /// 첫 번째 (가장 오래된) 기록 중 통증 레벨이 존재하는 값
    var firstAvailablePainLevel: Int? {
        guard let record = allRecords.first(where: { $0.painLevel != nil })
        else {
            return nil
        }
        return record.painLevel
    }

    /// 마지막 (가장 최근) 기록의 통증 레벨
    var latestPainLevel: Int? {
        guard let last = allRecords.last else { return nil }
        return last.painLevel
    }

    /// 통증 변화량 (처음 - 최근, 양수면 줄어든 것)
    var painChange: Int? {
        guard let first = firstAvailablePainLevel, let latest = latestPainLevel
        else { return nil }
        return first - latest
    }

    /// 통증 변화 설명 텍스트
    var painChangeText: String {
        guard totalRecordCount > 1,
            let change = painChange,
            change != 0
        else {
            return Strings.History.cardPainSame
        }

        if change > 0 {
            return Strings.History.cardPainBetter(levels: abs(change))
        } else {
            return Strings.History.cardPainWorse(levels: abs(change))
        }
    }

    /// 통증 레벨 서브타이틀 (최근 일주일 이내 데이터와 오늘 데이터 비교)
    var painSubtitle: String {
        // 측정 기록이 없는 경우
        guard !recentRecords.isEmpty else {
            return Strings.History.chartPainNoRecord
        }

        // 첫 측정인 경우 (기록이 1개만 있을 때)
        guard recentRecords.count > 1,
            let todayPain = latestPainLevel
        else {
            guard let firstPain = latestPainLevel else {
                return Strings.History.chartPainNoRecord
            }
            return Strings.History.chartPainFirstRecord(level: firstPain)
        }

        // 최근 일주일 이내의 최소 통증 레벨 (오늘 제외, 통증은 낮을수록 좋음)
        let previousRecords = recentRecords.dropLast()
        guard
            let minPreviousPain = previousRecords.compactMap({ $0.painLevel })
                .min()
        else {
            return Strings.History.chartPainFirstRecord(level: todayPain)
        }

        let difference = abs(todayPain - minPreviousPain)

        // 비교 (통증은 낮을수록 좋음)
        if todayPain < minPreviousPain {
            return Strings.History.chartPainBetter(
                improvement: difference,
                from: minPreviousPain
            )
        } else if todayPain == minPreviousPain {
            return Strings.History.chartPainSame(level: minPreviousPain)
        } else {
            return Strings.History.chartPainWorse(
                increase: difference,
                from: minPreviousPain
            )
        }
    }

    // MARK: - Chart Y-Axis Range

    var romMinValue: Double {
        // extensionAngle 값들 중 최소값 계산
        let validExtensionAngles =
            recentRecords
            .compactMap { $0.extensionAngle }
            .filter { $0.isFinite }

        guard let minExtension = validExtensionAngles.min() else {
            // extensionAngle이 없는 경우 기본값 0
            return 0
        }

        // 0보다 작으면 0으로 제한
        return max(minExtension, 0)
    }

    var romMaxValue: Double {
        // Use only finite, non-negative angles to avoid invalid ranges or NaN propagation
        let validAngles =
            recentRecords
            .compactMap { $0.flexionAngle }
            .filter { $0.isFinite && $0 >= 0 }

        guard let maxROM = validAngles.max() else {
            // Safe default when no valid angles exist
            return 0
        }

        // Padding for headroom; ensure upper bound is positive
        let padded = maxROM + 10
        return max(padded, 1)
    }

    var painMaxValue: Double {
        guard !recentRecords.isEmpty else { return 10 }
        let maxPain =
            recentRecords.compactMap { $0.painLevel }.map { Double($0) }.max()
            ?? 0
        // 데이터의 최댓값을 그대로 사용 (0일 경우 최소 1로 설정)
        return max(maxPain, 1)
    }

    // MARK: - Chart X-Axis Dates

    var recordDates: [Date] {
        recentRecords.map { $0.measuredDate }
    }

    var chartIndices: [Int] {
        Array(0..<recentRecords.count)
    }

    var chartIndicesAsDouble: [Double] {
        chartIndices.map { Double($0) }
    }

    // MARK: - Chart Data

    var chartData: [(index: Int, record: MeasuredRecord)] {
        Array(recentRecords.enumerated().map { (index: $0, record: $1) })
    }

    // MARK: - Helper Methods

    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy. M. d"
        return formatter.string(from: date)
    }

    func formatShortDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d"
        let result = formatter.string(from: date)
        return result
    }

    func loadRecentRecords() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let fetchedRecords = try await repository.loadRecords()
            let ascending = Array(fetchedRecords.reversed())
            allRecords = ascending
            recentRecords = Array(ascending.suffix(7))
            print(
                "📅 loadRecentRecords - Total records: \(allRecords.count), Recent records: \(recentRecords.count)"
            )
            for (index, record) in recentRecords.enumerated() {
                print(
                    "  [\(index)] Date: \(record.measuredDate), Formatted: \(formatShortDate(record.measuredDate))"
                )
            }
        } catch {
            print("❌ 최근 기록 로드 실패: \(error)")
            recentRecords = []
        }
    }

    func formatDateRange(startDate: Date, endDate: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateFormat = "yyyy/M/d"

        let start = formatter.string(from: startDate)
        formatter.dateFormat = "d"
        let end = formatter.string(from: endDate)

        return "\(start)~\(end)"
    }

    struct WeekDayData {
        let weekdayIndex: Int  // 0(일)~6(토)
        let date: Date
        let record: MeasuredRecord?
    }

    // 주어진 오프셋(기본: ROM 오프셋)에 따라 현재 주의 일-토 데이터를 가공함
    func getCurrentWeekData(type: ChartType) -> [WeekDayData] {
        let offset = type == .rom ? currentROMWeekOffset : currentPainWeekOffset
        let (startDate, endDate) = getWeekRange(offset: offset)

        // 일주일의 날짜 배열 생성
        var weekDates: [Date] = []
        for i in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: i, to: startDate)
            {
                weekDates.append(date)
            }
        }

        // 각 요일별(startDate ~ startDate+6)로 WeekDayData 생성; 기록 없으면 record: nil
        var recordsByDate: [Date: MeasuredRecord] = [:]
        for record in allRecords {
            let day = calendar.startOfDay(for: record.measuredDate)
            if day >= calendar.startOfDay(for: startDate)
                && day <= calendar.startOfDay(for: endDate)
            {
                recordsByDate[day] = record
            }
        }
        
        // 0~6(일~토) 모두 포함, 기록 없으면 nil
        return (0..<7).map { i in
            let date = calendar.date(byAdding: .day, value: i, to: startDate)!
            let day = calendar.startOfDay(for: date)
            return WeekDayData(
                weekdayIndex: i,
                date: date,
                record: recordsByDate[day]
            )
        }
    }

    private func getWeekRange(offset: Int) -> (start: Date, end: Date) {
        let today = Date()

        // 현재 주의 시작(일요일)을 구함
        let weekday = calendar.component(.weekday, from: today) - 1
        guard
            let thisWeekStart = calendar.date(
                byAdding: .day,
                value: -weekday,
                to: today
            )
        else {
            return (today, today)
        }

        // offset만큼 이전 주로 이동
        guard
            let targetWeekStart = calendar.date(
                byAdding: .weekOfYear,
                value: -offset,
                to: thisWeekStart
            ),
            let targetWeekEnd = calendar.date(
                byAdding: .day,
                value: 6,
                to: targetWeekStart
            )
        else {
            return (start: today, today)
        }

        return (targetWeekStart, targetWeekEnd)
    }
}

