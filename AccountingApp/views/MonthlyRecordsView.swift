// MonthlyRecordsView.swift
import SwiftUI

struct MonthlyRecordsView: View {
    @State private var currentMonth = 6
    @State private var currentYear = 2025
    @State private var selectedDate = Date()
    @State private var scrollOffset: CGFloat = 0
    
    let monthlyData = [
        DayRecord(date: "6月15日 星期六", total: 55, expenses: [
            ExpenseRecord(description: "午饭", amount: 14),
            ExpenseRecord(description: "地铁", amount: 6),
            ExpenseRecord(description: "奶茶看电影", amount: 35)
        ]),
        DayRecord(date: "6月14日 星期五", total: 128, expenses: [
            ExpenseRecord(description: "午饭", amount: 16),
            ExpenseRecord(description: "加班吃的俩汉堡T.T", amount: 32),
            ExpenseRecord(description: "理发", amount: 80)
        ]),
        DayRecord(date: "6月13日 星期四", total: 87, expenses: [
            ExpenseRecord(description: "午饭", amount: 11),
            ExpenseRecord(description: "晚饭外卖", amount: 35),
            ExpenseRecord(description: "奶茶", amount: 18),
            ExpenseRecord(description: "公交卡", amount: 23)
        ])
    ]
    
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
