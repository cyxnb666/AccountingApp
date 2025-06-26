// MonthlyRecordsView.swift
import SwiftUI

struct MonthlyRecordsView: View {
    @EnvironmentObject var dataManager: ExpenseDataManager
    @State private var currentMonth = Calendar.current.component(.month, from: Date())
    @State private var currentYear = Calendar.current.component(.year, from: Date())
    @State private var selectedDate = Date()
    @State private var scrollOffset: CGFloat = 0
    @State private var cachedMonthlyData: [DayRecord] = []
    @State private var lastCachedMonth: Int = 0
    @State private var lastCachedYear: Int = 0
    @State private var lastExpenseCount: Int = 0
    @State private var boundaryMessage: String = ""
    @State private var showBoundaryMessage = false
    
    private var monthlyData: [DayRecord] {
        // 缓存机制：只有当月份、年份或数据变化时才重新计算
        if currentMonth != lastCachedMonth || 
           currentYear != lastCachedYear || 
           dataManager.expenses.count != lastExpenseCount {
            
            cachedMonthlyData = calculateMonthlyData()
            lastCachedMonth = currentMonth
            lastCachedYear = currentYear
            lastExpenseCount = dataManager.expenses.count
        }
        return cachedMonthlyData
    }
    
    private func calculateMonthlyData() -> [DayRecord] {
        let calendar = Calendar.current
        let startOfMonth = calendar.date(from: DateComponents(year: currentYear, month: currentMonth, day: 1))!
        let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth)!
        
        let monthlyExpenses = dataManager.expenses.filter { expense in
            expense.date >= startOfMonth && expense.date <= endOfMonth
        }
        
        let groupedByDay = Dictionary(grouping: monthlyExpenses) { expense in
            calendar.startOfDay(for: expense.date)
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "M月d日 EEEE"
        formatter.locale = Locale(identifier: "zh_CN")
        
        return groupedByDay.compactMap { (date, expenses) in
            let total = expenses.reduce(0) { $0 + Int($1.amount) }
            
            return DayRecord(
                date: formatter.string(from: date),
                actualDate: date,
                total: total,
                expenses: expenses
            )
        }.sorted { $0.actualDate > $1.actualDate }
    }
    
    var monthlyTotal: Int {
        monthlyData.reduce(0) { $0 + $1.total }
    }
    
    var isHeaderCollapsed: Bool {
        scrollOffset > 50
    }
    
    // 获取数据的最早月份
    private var earliestDataMonth: (year: Int, month: Int)? {
        guard !dataManager.expenses.isEmpty else { return nil }
        let sortedExpenses = dataManager.expenses.sorted { $0.date < $1.date }
        guard let earliestDate = sortedExpenses.first?.date else { return nil }
        let calendar = Calendar.current
        return (year: calendar.component(.year, from: earliestDate), 
                month: calendar.component(.month, from: earliestDate))
    }
    
    // 获取数据的最晚月份
    private var latestDataMonth: (year: Int, month: Int)? {
        guard !dataManager.expenses.isEmpty else { return nil }
        let sortedExpenses = dataManager.expenses.sorted { $0.date > $1.date }
        guard let latestDate = sortedExpenses.first?.date else { return nil }
        let calendar = Calendar.current
        return (year: calendar.component(.year, from: latestDate), 
                month: calendar.component(.month, from: latestDate))
    }
    
    // 检查是否可以切换到指定月份
    private func canSwitchToMonth(year: Int, month: Int) -> Bool {
        guard let earliest = earliestDataMonth, let latest = latestDataMonth else { return false }
        
        // 将年月转换为可比较的数字
        let targetMonthValue = year * 12 + month
        let earliestMonthValue = earliest.year * 12 + earliest.month
        let latestMonthValue = latest.year * 12 + latest.month
        
        return targetMonthValue >= earliestMonthValue && targetMonthValue <= latestMonthValue
    }
    
    // 显示边界消息
    private func showBoundaryAlert(_ message: String) {
        boundaryMessage = message
        withAnimation(.easeInOut(duration: 0.3)) {
            showBoundaryMessage = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.easeInOut(duration: 0.3)) {
                showBoundaryMessage = false
            }
        }
    }
    
    // 辅助函数：获取前一个月
    private func previousMonth(year: Int, month: Int) -> (year: Int, month: Int) {
        if month == 1 {
            return (year: year - 1, month: 12)
        } else {
            return (year: year, month: month - 1)
        }
    }
    
    // 辅助函数：获取下一个月
    private func nextMonth(year: Int, month: Int) -> (year: Int, month: Int) {
        if month == 12 {
            return (year: year + 1, month: 1)
        } else {
            return (year: year, month: month + 1)
        }
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
                    .environmentObject(dataManager)
                    
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
                            DayRecordView(dayRecord: dayRecord, dataManager: dataManager)
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
            .gesture(
                DragGesture(minimumDistance: 30, coordinateSpace: .local)
                    .onEnded { value in
                        let threshold: CGFloat = 50
                        // 只有当水平滑动距离大于垂直滑动距离时才处理水平手势
                        if abs(value.translation.width) > abs(value.translation.height) && abs(value.translation.width) > threshold {
                            if value.translation.width > threshold {
                                // 右滑 - 前一个月
                                let (prevYear, prevMonth) = previousMonth(year: currentYear, month: currentMonth)
                                if canSwitchToMonth(year: prevYear, month: prevMonth) {
                                    withAnimation(.spring()) {
                                        currentYear = prevYear
                                        currentMonth = prevMonth
                                    }
                                } else {
                                    showBoundaryAlert("已经是最早的数据月份了")
                                }
                            } else if value.translation.width < -threshold {
                                // 左滑 - 下一个月
                                let (nextYear, nextMonth) = nextMonth(year: currentYear, month: currentMonth)
                                if canSwitchToMonth(year: nextYear, month: nextMonth) {
                                    withAnimation(.spring()) {
                                        currentYear = nextYear
                                        currentMonth = nextMonth
                                    }
                                } else {
                                    showBoundaryAlert("已经是最新的数据月份了")
                                }
                            }
                        }
                    }
            )
            .overlay(
                // 边界消息提示
                VStack {
                    if showBoundaryMessage {
                        Text(boundaryMessage)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color.black.opacity(0.8))
                            )
                            .transition(.opacity.combined(with: .scale))
                    }
                    Spacer()
                }
                .padding(.top, 100)
            )
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
    let dataManager: ExpenseDataManager
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
                    ForEach(dayRecord.expenses) { expense in
                        MonthlyExpenseRowView(expense: expense, dataManager: dataManager)
                            .transition(.asymmetric(
                                insertion: .opacity.combined(with: .offset(y: -10)),
                                removal: .opacity.combined(with: .offset(y: -5))
                            ))
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

struct MonthlyExpenseRowView: View {
    let expense: Expense
    let dataManager: ExpenseDataManager
    @State private var showingDeleteAlert = false
    
    var body: some View {
        HStack {
            HStack(spacing: 12) {
                Image(systemName: expense.categoryIcon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.blue)
                    .frame(width: 16)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(expense.description)
                        .font(.system(size: 14))
                        .foregroundColor(.primary)
                    
                    Text(expense.categoryName)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text("¥\(String(format: "%.0f", expense.amount))")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
            }
            
            Button(action: {
                showingDeleteAlert = true
            }) {
                Image(systemName: "trash")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.red)
                    .frame(width: 28, height: 28)
                    .background(
                        Circle()
                            .fill(Color.red.opacity(0.1))
                    )
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemGray6))
        )
        .alert("确认删除", isPresented: $showingDeleteAlert) {
            Button("取消", role: .cancel) { }
            Button("删除", role: .destructive) {
                deleteExpense()
            }
        } message: {
            Text("确定要删除这笔支出记录吗？")
        }
    }
    
    private func deleteExpense() {
        if let index = dataManager.expenses.firstIndex(where: { $0.id == expense.id }) {
            withAnimation(.easeInOut) {
                dataManager.deleteExpense(at: index)
            }
        }
    }
}

// Data Models
struct DayRecord {
    let date: String
    let actualDate: Date
    let total: Int
    let expenses: [Expense]
}

// Dynamic Header with smooth animations
struct DynamicMonthlyHeaderView: View {
    @EnvironmentObject var dataManager: ExpenseDataManager
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
                        
                        if dataManager.monthlyBudget > 0 {
                            Rectangle()
                                .fill(.white.opacity(0.3))
                                .frame(width: 1, height: 40)
                            
                            VStack(spacing: 4) {
                                Text("¥\(Int(dataManager.monthlyBudget - Double(monthlyTotal)))")
                                    .font(.system(size: 24, weight: .bold, design: .rounded))
                                    .foregroundColor(Double(monthlyTotal) > dataManager.monthlyBudget ? .red : .white)
                                Text("预算余额")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.white.opacity(0.8))
                            }
                        } else {
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