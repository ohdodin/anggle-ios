//
//  History.swift
//  gacha
//
//  Created by 차원준 on 10/26/25.
//

import Charts
import SwiftData
import SwiftUI

enum ChartType: Hashable {
    case rom
    case pain
}

struct History: View {
    @EnvironmentObject var vm: HistoryViewModel

    // MARK: - Body
    var body: some View {
        ZStack(alignment: .topTrailing) {
            if vm.isLoading {
                Text("Loading...")
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 32) {
                            // MARK: - Summary Cards
                            HStack(spacing: 14) {
                                // Rom Card
                                romSummaryCard(proxy: proxy)

                                // Pain Card
                                painSummaryCard(proxy: proxy)
                            }

                            // MARK: - ROM Chart
                            VStack(alignment: .leading, spacing: 16) {
                                ChartText(chartType: .rom)
                                if !vm.chartData.isEmpty {
                                    romChart
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(16)
                            .background(.white)
                            .cornerRadius(24)

                            // MARK: - Pain Chart
                            VStack(alignment: .leading, spacing: 16) {
                                ChartText(chartType: .pain)
                                if !vm.chartData.isEmpty {
                                    painChart
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(16)
                            .background(.white)
                            .cornerRadius(24)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        .padding(.bottom, 20)
                    }
                }

            }
        }
        .background(Color("BackgoundSecondary"))
        .task {
            await vm.loadRecentRecords()
        }
    }

    // MARK: - Chart Text
    private func ChartText(chartType: ChartType) -> some View {
        return VStack(alignment: .leading, spacing: 4) {
            // Title
            Text(
                chartType == .rom
                    ? Strings.History.chartRomTitle
                    : Strings.History.chartPainTitle
            )
            .font(.displaySublineBold)
            .foregroundColor(.blue700)
            .id(chartType == .rom ? "romChart" : "painChart")
            // Subtitle
            if vm.chartData.isEmpty {
                Text(
                    chartType == .rom
                        ? Strings.History.chartRomNoRecord
                        : Strings.History.chartPainNoRecord
                )
                .font(.displayFootnoteRegular)
                .frame(
                    maxWidth: .infinity,
                    alignment: .leading
                )
            } else {
                Text(chartType == .rom ? vm.romSubtitle : vm.painSubtitle)
                    .font(.displayFootnoteRegular)
            }
        }
        .opacity(
            (chartType == .rom ? vm.selectedROMIndex : vm.selectedPainIndex)
                != nil ? 0 : 1
        )
        .animation(
            .easeInOut(duration: 0.1),
            value: (chartType == .rom
                ? vm.selectedROMIndex : vm.selectedPainIndex)
        )
    }

    // MARK: - Chart Views
    private var romChart: some View {
        let data = vm.chartData
        let selectedIndex = vm.selectedROMIndex

        let weekData = vm.getCurrentWeekData()  // 빈 데이터 가공

        return Chart {
            ForEach(0..<vm.week.count, id: \.self) { weekdayIndex in
                let dayData = weekData[weekdayIndex]

                if let record = dayData.record {
                    BarMark(
                        x: .value("weekday", weekdayIndex),
                        yStart: .value("angle", record.extensionAngle ?? 0),
                        yEnd: .value("angle", record.flexionAngle ?? 0),
                        width: .fixed(12)
                    )
                    .foregroundStyle(
                        Color("Blue500")
                    )
                    .cornerRadius(4)
                } else {
                    // 데이터가 없는 날 (빈 바)
                    BarMark(
                        x: .value("weekday", weekdayIndex),
                        yStart: .value("angle", 0),
                        yEnd: .value("angle", 0.5),
                        width: .fixed(12)
                    )
                    .foregroundStyle(Color("Gray200").opacity(0.3))
                    .cornerRadius(4)
                }
            }

            if let selectedIndex = selectedIndex,
                selectedIndex >= 0 && selectedIndex < vm.week.count
            {
                let adjustedIndex = nearestAvailableIndex(
                    from: selectedIndex,
                    in: weekData
                )
                if let adjustedIndex = adjustedIndex {
                    RuleMark(x: .value("Selected", adjustedIndex))
                        .foregroundStyle(Color("Gray300"))
                        .zIndex(-1)
                        .annotation(
                            position: .top,
                            spacing: 8,
                            overflowResolution: .init(
                                x: .fit(to: .chart),
                                y: .disabled
                            )
                        ) {
                            romAnnotation(at: adjustedIndex)
                        }
                }
            }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: 1)) {
                value in
                if let index = value.as(Double.self) {
                    if let index = value.as(Int.self),
                        index >= 0 && index < vm.week.count
                    {
                        AxisValueLabel {
                            Text(vm.week[index])
                                .font(.caption)
                                .foregroundColor(.gray)
                                .offset(x: -10)
                        }
                    }
                }
            }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: 1)) { value in
                if let index = value.as(Int.self),
                    index >= 0 && index < 7
                {
                    AxisValueLabel {
                        Text(vm.week[index])
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks { value in
                AxisValueLabel {
                    if let angle = value.as(Double.self) {
                        Text("\(Int(angle))°")
                    }
                }
                AxisGridLine()
            }
        }
        .chartXScale(domain: -0.5...6.5)
        .chartYScale(domain: 0...max(150, vm.romMaxValue))
        .chartXSelection(value: $vm.selectedROMIndex)  //롱프레스 감지
        .frame(height: 361)
        .padding(.top, 20)
    }

    @ViewBuilder
    private func romAnnotation(at explicitIndex: Int? = nil) -> some View {
        if let selectedIndex = explicitIndex ?? vm.selectedROMIndex,
            selectedIndex >= 0 && selectedIndex < vm.week.count
        {
            let weekData = vm.getCurrentWeekData()

            let selectedRecord = weekData[selectedIndex]
            VStack(alignment: .center, spacing: 4) {
                Text(Strings.History.cardRomTitle)
                    .font(.displayCaption1Semibold)
                    .foregroundStyle(Color("Gray700"))
                    .frame(maxWidth: .infinity, alignment: .topLeading)

                Text(
                    "\(Int(selectedRecord.record?.extensionAngle ?? 0))°~\(Int(selectedRecord.record?.flexionAngle ?? 0))°"
                )
                .font(.displayTitle2Semibold)
                .foregroundStyle(Color("Gray900"))
                .frame(maxWidth: .infinity, alignment: .topLeading)

                Text(
                    selectedRecord.record?.measuredDate != nil
                        ? vm.formatDate(selectedRecord.record!.measuredDate)
                        : "-"
                )
                .font(.displayCaption1Semibold)
                .foregroundStyle(Color("Gray700"))
                .frame(maxWidth: .infinity, alignment: .topLeading)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .frame(width: 125, alignment: .center)
            .background(Color("Gray100"))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    private var painChart: some View {
        let data = vm.chartData
        let selectedIndex = vm.selectedPainIndex

        return Chart {
            ForEach(data, id: \.record.id) { item in
                LineMark(
                    x: .value("index", item.index),
                    y: .value("pain", item.record.painLevel ?? 0)
                )
                .foregroundStyle(Color(.blue500))
                .interpolationMethod(.catmullRom)

                PointMark(
                    x: .value("index", item.index),
                    y: .value("pain", item.record.painLevel ?? 0)
                )
                .foregroundStyle(Color("Blue500"))
                .symbolSize(80)
            }

            if let selectedIndex = selectedIndex,
                selectedIndex >= 0 && selectedIndex < data.count
            {
                RuleMark(x: .value("Selected", selectedIndex))
                    .foregroundStyle(Color("Gray300"))
                    .zIndex(-1)
                    .annotation(
                        position: .top,
                        spacing: 0,
                        overflowResolution: .init(
                            x: .fit(to: .chart),
                            y: .disabled
                        )
                    ) {
                        painAnnotation
                    }
            }
        }
        .chartXAxis {
            AxisMarks(position: .bottom, values: vm.chartIndicesAsDouble) {
                value in
                if let doubleValue = value.as(Double.self) {
                    let index = Int(round(doubleValue))
                    // 정확한 인덱스 값인지 확인 (0.01 이내 오차 허용)
                    if abs(doubleValue - Double(index)) < 0.01,
                        index >= 0 && index < vm.recentRecords.count
                    {
                        let record = vm.recentRecords[index]
                        let dateStr = vm.formatShortDate(record.measuredDate)
                        AxisValueLabel {
                            Text(dateStr)
                                .offset(x: -17)
                        }
                    } else {
                        AxisGridLine()
                    }
                }
            }
        }
        .chartYScale(domain: 0...10)
        //        .chartXScale(domain: domain)
        .chartXSelection(value: $vm.selectedPainIndex)
        .frame(height: 250)
        .padding(.top, 20)
    }

    @ViewBuilder
    private var painAnnotation: some View {
        if let selectedIndex = vm.selectedPainIndex,
            selectedIndex >= 0 && selectedIndex < vm.recentRecords.count
        {
            let selectedRecord = vm.recentRecords[selectedIndex]
            VStack(alignment: .leading, spacing: 4) {
                Text(Strings.History.cardPainTitle)
                    .font(.displayCaption1Semibold)
                    .foregroundStyle(Color("Gray700"))
                    .frame(maxWidth: .infinity, alignment: .topLeading)

                Text(formatPainLevel(selectedRecord.painLevel))
                    .font(.displayTitle2Semibold)
                    .foregroundStyle(Color("Gray900"))
                    .frame(maxWidth: .infinity, alignment: .topLeading)

                Text(vm.formatDate(selectedRecord.measuredDate))
                    .font(.displayCaption1Semibold)
                    .foregroundStyle(Color("Gray700"))
                    .frame(maxWidth: .infinity, alignment: .topLeading)

            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .frame(width: 120, alignment: .center)
            .background(Color("Gray100"))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    // MARK: - Summary Cards

    @ViewBuilder
    private func romSummaryCard(proxy: ScrollViewProxy) -> some View {
        VStack(alignment: .leading) {

            // ROM 수치 표시
            HStack(spacing: 0) {
                if vm.totalRecordCount < 2 {
                } else if let first = vm.firstAvailableROM,
                    let latest = vm.latestROM
                {
                    // 기록이 여러 개일 때
                    let change = latest - first
                    Text("\(change > 0 ? "↑" : "")\(change)°")
                        .font(.roundedTitle1Bold)
                        .foregroundColor(Color("Gray900"))
                }
                Spacer()

            }

            Spacer()

            VStack(alignment: .leading, spacing: 4) {
                // 헤더
                HStack {
                    Text(Strings.History.cardRomTitle)
                        .font(.displaySublineBold)
                        .foregroundColor(Color("Blue700"))
                }

                // 변화 설명 텍스트
                Text(
                    vm.totalRecordCount < 2
                        ? Strings.History.cardRomUnder2
                        : vm.romChangeText
                )
                .font(
                    vm.totalRecordCount < 2
                        ? .displayFootnoteRegular : .displayCalloutRegular
                )
                .foregroundColor(Color("Gray700"))
                .lineLimit(3)
            }

        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .frame(width: 173, height: 173)
        .background(Color.white)
        .cornerRadius(15)
    }
    @ViewBuilder
    private func painSummaryCard(proxy: ScrollViewProxy) -> some View {

        VStack(alignment: .leading) {

            // 통증 레벨 바 표시
            HStack(spacing: 0) {
                if vm.totalRecordCount < 2 {

                } else if let first = vm.firstAvailablePainLevel,
                    let latest = vm.latestPainLevel
                {
                    // 기록이 여러 개일 때
                    let change = latest - first
                    Text(
                        "\(change < 0 ? "↓" : "")\(abs(change)) \(Strings.History.cardPainStep)"
                    )
                    .font(.roundedTitle1Bold)
                    .foregroundColor(Color("Gray900"))
                }
                Spacer()
            }

            Spacer()

            VStack(alignment: .leading, spacing: 4) {

                // 헤더
                HStack {
                    Text(Strings.History.chartPainTitle)
                        .font(.displaySublineBold)
                        .foregroundColor(Color("Blue700"))
                }

                // 변화 설명 텍스트
                Text(
                    vm.totalRecordCount == 0
                        ? Strings.History.cardPainNoRecord
                        : (vm.totalRecordCount < 2
                            ? Strings.History.cardPainFirstRecord
                            : vm.painChangeText)
                )
                .font(
                    vm.totalRecordCount < 2
                        ? .displayFootnoteRegular : .displayCalloutRegular
                )
                .foregroundColor(Color("Gray700"))
                .lineLimit(3)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .frame(width: 173, height: 173)
        .background(Color.white)
        .cornerRadius(15)
        //        }

    }

    // MARK: - Helper Methods
    private func formatPainLevel(_ level: Int?) -> String {
        guard let level = level else { return "-" }
        return "\(level)"
    }

    // 가장 가까운 기록이 있는 인덱스를 찾는 헬퍼
    private func nearestAvailableIndex(
        from index: Int,
        in weekData: [HistoryViewModel.WeekDayData]
    ) -> Int? {
        guard index >= 0 && index < weekData.count else { return nil }
        if weekData[index].record != nil { return index }
        var offset = 1
        while index - offset >= 0 || index + offset < weekData.count {
            if index - offset >= 0, weekData[index - offset].record != nil {
                return index - offset
            }
            if index + offset < weekData.count,
                weekData[index + offset].record != nil
            {
                return index + offset
            }
            offset += 1
        }
        return nil
    }
}

// MARK: - Previews

struct HistoryPreviewWrapper: View {
    @StateObject private var vm: HistoryViewModel

    init(scenario: MockRecordRepository.Scenario) {
        _vm = StateObject(
            wrappedValue: HistoryViewModel(
                repository: MockRecordRepository(scenario: scenario)
            )
        )
    }

    var body: some View {
        NavigationStack {
            History()
                .environmentObject(vm)
                .task {
                    await vm.loadRecentRecords()
                }
        }
    }
}

#Preview("No Record") {
    HistoryPreviewWrapper(scenario: .noRecord)
}

#Preview("Single Record") {
    HistoryPreviewWrapper(scenario: .singleRecord)
}

#Preview("Positive Progress (67° → 97°)") {
    HistoryPreviewWrapper(scenario: .multipleRecordsPositive)
}

#Preview("Negative Progress") {
    HistoryPreviewWrapper(scenario: .multipleRecordsNegative)
}

#Preview("23 Days - 7 Records") {
    HistoryPreviewWrapper(scenario: .sevenRecords23Days)
}

#Preview("No Change") {
    HistoryPreviewWrapper(scenario: .noChange)
}
//
//#Preview("Extended Records (11+)") {
//    HistoryPreviewWrapper(scenario: .extendedRecords)
//}
