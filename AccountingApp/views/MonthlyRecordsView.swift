// MonthlyRecordsView.swift
import SwiftUI

struct MonthlyRecordsView: View {
    @EnvironmentObject var dataManager: ExpenseDataManager
    @State private var currentMonth = Calendar.current.component(.month, from: Date())
    @State private var currentYear = Calendar.current.component(.year, from: Date())
    @State private var selectedDate = Date()
    @State private var scrollOffset: CGFloat = 0
    
    var monthlyData: [DayRecord] {
        let calendar = Calendar.current
        let startOfMonth = calendar.date(from: DateComponents(year: currentYear, month: currentMonth, day: 1))!
        let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth)!
        
        let monthlyExpenses = dataManager.expenses.filter { expense in
            expense.date >= startOfMonth && expense.date <= endOfMonth
        }
        
        let groupedByDay = Dictionary(grouping: monthlyExpenses) { expense in
            calendar.startOfDay(for: expense.date)
        }
        
        return groupedByDay.map { (date, expenses) in
            let formatter = DateFormatter()
            formatter.dateFormat = "M月d日 EEEE"
            formatter.locale = Locale(identifier: "zh_CN")
            
            let dayExpenses = expenses.map { ExpenseRecord(description: $0.description, amount: Int($0.amount)) }
            let total = expenses.reduce(0) { $0 + Int($1.amount) }
            
            return DayRecord(
                date: formatter.string(from: date),
                total: total,
                expenses: dayExpenses
            )
        }.sorted { first, second in
            let firstDate = groupedByDay.keys.first { key in
                let formatter = DateFormatter()
                formatter.dateFormat = "M月d日 EEEE"
                formatter.locale = Locale(identifier: "zh_CN")
                return formatter.string(from: key) == first.date
            }
            let secondDate = groupedByDay.keys.first { key in
                let formatter = DateFormatter()
                formatter.dateFormat = "M月d日 EEEE"
                formatter.locale = Locale(identifier: "zh_CN")
                return formatter.string(from: key) == second.date
            }
            return (firstDate ?? Date()) > (secondDate ?? Date())
        }
    }
    
    var monthlyTotal: Int {
        monthlyData.reduce(0) { $0 + $1.total }
    }
    
    var isHeaderCollapsed: Bool {
        scrollOffset > 50
    }
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 0) {
                    // Dynamic Header
                    DynamicMonthlyHeaderView(
                        currentMonth: currentMonth,
                        currentYear: currentYear,
                        monthlyTotal: monthlyTotal,
                        isCollapsed: isHeaderCollapsed
                    )
                    
                    // Month Selector (now sticky)
                    MonthSelectorView(
                        currentMonth: $currentMonth,
                        currentYear: $currentYear
                    )
                    .background(
                        .ultraThinMaterial,
                        in: Rectangle()
                    )
                    .zIndex(1)
                    
                    // Records List
                    LazyVStack(spacing: 16) {
                        ForEach(Array(monthlyData.enumerated()), id: \.offset) { index, dayRecord in
                            DayRecordView(dayRecord: dayRecord)
                                .animation(.easeInOut.delay(Double(index) * 0.1), value: monthlyData.count)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 100) // Space for tab bar
                }
                .background(
                    GeometryReader { scrollGeometry in
                        Color.clear
                            .preference(key: ScrollOffsetPreferenceKey.self, value: scrollGeometry.frame(in: .named("scroll")).minY)
                    }
                )
            }
            .coordinateSpace(name: "scroll")
            .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                withAnimation(.easeInOut(duration: 0.2)) {
                    scrollOffset = -value
                }
            }
            .background(Color(.systemGroupedBackground))
        }
    }
}

struct MonthlyHeaderView: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.15, green: 0.5, blue: 0.6),
                    Color(red: 0.1, green: 0.4, blue: 0.5)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            VStack(spacing: 8) {
                Text("月度记录")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text("查看每月支出明细")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .padding(.top, 50)
            .padding(.bottom, 30)
        }
        .clipShape(
            UnevenRoundedRectangle(
                topLeadingRadius: 0,
                bottomLeadingRadius: 30,
                bottomTrailingRadius: 30,
                topTrailingRadius: 0
            )
        )
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
}

struct MonthSelectorView: View {
    @Binding var currentMonth: Int
    @Binding var currentYear: Int
    
    var body: some View {
        HStack {
            Button(action: previousMonth) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(.ultraThinMaterial)
                    )
            }
            
            Spacer()
            
            Text("\(currentYear)年\(currentMonth)月")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.primary)
                .animation(.spring(), value: currentMonth)
                .animation(.spring(), value: currentYear)
            
            Spacer()
            
            Button(action: nextMonth) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(.ultraThinMaterial)
                    )
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 15)
        .background(.ultraThinMaterial)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private func previousMonth() {
        withAnimation(.spring()) {
            currentMonth -= 1
            if currentMonth < 1 {
                currentMonth = 12
                currentYear -= 1
            }
        }
    }
    
    private func nextMonth() {
        withAnimation(.spring()) {
            currentMonth += 1
            if currentMonth > 12 {
                currentMonth = 1
                currentYear += 1
            }
        }
    }
}

struct DayRecordView: View {
    let dayRecord: DayRecord
    @State private var isExpanded = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Day Header
            Button(action: {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(dayRecord.date)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        Text("\(dayRecord.expenses.count) 笔消费")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("¥\(dayRecord.total)")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.primary)
                        
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Expenses List
            if isExpanded {
                VStack(spacing: 8) {
                    ForEach(Array(dayRecord.expenses.enumerated()), id: \.offset) { index, expense in
                        HStack {
                            Circle()
                                .fill(.primary.opacity(0.2))
                                .frame(width: 6, height: 6)
                            
                            Text(expense.description)
                                .font(.system(size: 14))
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Text("¥\(expense.amount)")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.primary)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(.systemGray6))
                        )
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .offset(y: -10)),
                            removal: .opacity.combined(with: .offset(y: -5))
                        ))
                        .animation(.easeInOut.delay(Double(index) * 0.05), value: isExpanded)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
                .transition(.opacity.combined(with: .offset(y: -10)))
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(.primary.opacity(isExpanded ? 0.3 : 0.1), lineWidth: 1)
        )
        .scaleEffect(isExpanded ? 1.02 : 1.0)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isExpanded)
    }
}

// Data Models
struct DayRecord {
    let date: String
    let total: Int
    let expenses: [ExpenseRecord]
}

struct ExpenseRecord {
    let description: String
    let amount: Int
}

// Dynamic Header with smooth animations
struct DynamicMonthlyHeaderView: View {
    let currentMonth: Int
    let currentYear: Int
    let monthlyTotal: Int
    let isCollapsed: Bool
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.15, green: 0.5, blue: 0.6),
                    Color(red: 0.1, green: 0.4, blue: 0.5)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            VStack(spacing: isCollapsed ? 4 : 12) {
                if !isCollapsed {
                    Text("月度记录")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .transition(.opacity.combined(with: .scale))
                    
                    Text("查看每月支出明细")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                        .transition(.opacity.combined(with: .offset(y: -10)))
                    
                    // Monthly stats
                    HStack(spacing: 20) {
                        VStack(spacing: 4) {
                            Text("¥\(monthlyTotal)")
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            Text("本月支出")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                        }
                        
                        Rectangle()
                            .fill(.white.opacity(0.3))
                            .frame(width: 1, height: 40)
                        
                        VStack(spacing: 4) {
                            Text("\(Int(Double(monthlyTotal) / 30))")
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            Text("日均支出")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                    .transition(.opacity.combined(with: .scale))
                } else {
                    Text("月度记录")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .transition(.opacity.combined(with: .scale))
                }
            }
            .padding(.top, isCollapsed ? 20 : 50)
            .padding(.bottom, isCollapsed ? 15 : 30)
            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: isCollapsed)
        }
        .frame(height: isCollapsed ? 80 : 160)
        .clipShape(
            UnevenRoundedRectangle(
                topLeadingRadius: 0,
                bottomLeadingRadius: 30,
                bottomTrailingRadius: 30,
                topTrailingRadius: 0
            )
        )
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: isCollapsed)
    }
}

// Preference key for tracking scroll offset
struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
