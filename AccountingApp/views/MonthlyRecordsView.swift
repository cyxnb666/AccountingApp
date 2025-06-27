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
    @State private var searchText = ""
    @State private var selectedCategoryFilter = "all"
    @State private var showingFilterOptions = false
    
    private var monthlyData: [DayRecord] {
        // 缓存机制：只有当月份、年份、数据、搜索条件或筛选条件变化时才重新计算
        if currentMonth != lastCachedMonth || 
           currentYear != lastCachedYear || 
           dataManager.expenses.count != lastExpenseCount {
            
            cachedMonthlyData = calculateMonthlyData()
            lastCachedMonth = currentMonth
            lastCachedYear = currentYear
            lastExpenseCount = dataManager.expenses.count
        }
        return applySearchAndFilter(to: cachedMonthlyData)
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
    
    private func applySearchAndFilter(to records: [DayRecord]) -> [DayRecord] {
        return records.compactMap { dayRecord in
            let filteredExpenses = dayRecord.expenses.filter { expense in
                // 搜索筛选
                let matchesSearch = searchText.isEmpty || 
                    expense.description.localizedCaseInsensitiveContains(searchText) ||
                    expense.categoryName.localizedCaseInsensitiveContains(searchText)
                
                // 分类筛选
                let matchesCategory = selectedCategoryFilter == "all" || 
                    expense.category == selectedCategoryFilter
                
                return matchesSearch && matchesCategory
            }
            
            // 如果筛选后没有支出记录，则不显示这一天
            if filteredExpenses.isEmpty {
                return nil
            }
            
            let total = filteredExpenses.reduce(0) { $0 + Int($1.amount) }
            return DayRecord(
                date: dayRecord.date,
                actualDate: dayRecord.actualDate,
                total: total,
                expenses: filteredExpenses
            )
        }
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
                    .ignoresSafeArea(.all, edges: .top)
                    
                    // Month Selector (now sticky)
                    MonthSelectorView(
                        currentMonth: $currentMonth,
                        currentYear: $currentYear
                    )
                    .environmentObject(dataManager)
                    .background(
                        .ultraThinMaterial,
                        in: Rectangle()
                    )
                    .zIndex(1)
                    
                    // Search and Filter Section
                    SearchAndFilterSection(
                        searchText: $searchText,
                        selectedCategoryFilter: $selectedCategoryFilter,
                        showingFilterOptions: $showingFilterOptions,
                        dataManager: dataManager
                    )
                    .padding(.horizontal, 16)
                    
                    // Trend Charts Section
                    TrendChartsSection(
                        currentMonth: currentMonth,
                        currentYear: currentYear,
                        dataManager: dataManager
                    )
                    .padding(.horizontal, 4)
                    
                    
                    // Records List
                    LazyVStack(spacing: 12) {
                        ForEach(Array(monthlyData.enumerated()), id: \.offset) { index, dayRecord in
                            DayRecordView(dayRecord: dayRecord, dataManager: dataManager)
                                .animation(.easeInOut.delay(Double(index) * 0.1), value: monthlyData.count)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
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
            .ignoresSafeArea(.container, edges: .top)
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
    @EnvironmentObject var dataManager: ExpenseDataManager
    @State private var boundaryMessage: String = ""
    @State private var showBoundaryMessage = false
    
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
        
        let targetMonthValue = year * 12 + month
        let earliestMonthValue = earliest.year * 12 + earliest.month
        let latestMonthValue = latest.year * 12 + latest.month
        
        return targetMonthValue >= earliestMonthValue && targetMonthValue <= latestMonthValue
    }
    
    // 显示边界消息
    private func showBoundaryAlert(_ message: String) {
        boundaryMessage = message
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        withAnimation(.easeInOut(duration: 0.3)) {
            showBoundaryMessage = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeInOut(duration: 0.3)) {
                showBoundaryMessage = false
            }
        }
    }
    
    // 辅助函数：获取前一个月
    private func previousMonthData(year: Int, month: Int) -> (year: Int, month: Int) {
        if month == 1 {
            return (year: year - 1, month: 12)
        } else {
            return (year: year, month: month - 1)
        }
    }
    
    // 辅助函数：获取下一个月
    private func nextMonthData(year: Int, month: Int) -> (year: Int, month: Int) {
        if month == 12 {
            return (year: year + 1, month: 1)
        } else {
            return (year: year, month: month + 1)
        }
    }
    
    var body: some View {
        HStack {
            Button(action: previousMonth) {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                    Image(systemName: "chevron.left")
                        .font(.system(size: 12, weight: .medium))
                        .opacity(0.6)
                }
                .foregroundColor(.primary)
                .frame(width: 44, height: 44)
                .background(
                    ZStack {
                        Circle()
                            .fill(.ultraThinMaterial)
                        
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.white.opacity(0.3), .clear],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    }
                )
                .overlay(
                    Circle()
                        .stroke(
                            Color.brandPrimary.opacity(0.15),
                            lineWidth: 1
                        )
                )
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
            }
            
            Spacer()
            
            VStack(spacing: 2) {
                Text("\(currentYear)年\(currentMonth)月")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.primary)
                    .animation(.spring(), value: currentMonth)
                    .animation(.spring(), value: currentYear)
                
                Text("← 滑动切换 →")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.secondary.opacity(0.7))
            }
            
            Spacer()
            
            Button(action: nextMonth) {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .medium))
                        .opacity(0.6)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.primary)
                .frame(width: 44, height: 44)
                .background(
                    ZStack {
                        Circle()
                            .fill(.ultraThinMaterial)
                        
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.white.opacity(0.3), .clear],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    }
                )
                .overlay(
                    Circle()
                        .stroke(
                            Color.brandPrimary.opacity(0.15),
                            lineWidth: 1
                        )
                )
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 18)
        .background(
            ZStack {
                // 主背景
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                
                // 渐变叠加
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.15, green: 0.5, blue: 0.6).opacity(0.05),
                                Color(red: 0.1, green: 0.4, blue: 0.5).opacity(0.03)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                // 顶部高光
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [.white.opacity(0.2), .clear],
                            startPoint: .top,
                            endPoint: UnitPoint(x: 0.5, y: 0.3)
                        )
                    )
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    LinearGradient(
                        colors: [Color.brandPrimary.opacity(0.2), Color.brandSecondary.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: .black.opacity(0.12), radius: 12, x: 0, y: 6)
        .shadow(color: Color.brandPrimary.opacity(0.06), radius: 20, x: 0, y: 8)
        .gesture(
            DragGesture(minimumDistance: 20, coordinateSpace: .local)
                .onEnded { value in
                    let threshold: CGFloat = 80
                    let horizontalDistance = abs(value.translation.width)
                    let verticalDistance = abs(value.translation.height)
                    
                    // 只有当水平滑动距离明显大于垂直滑动距离时才处理
                    if horizontalDistance > threshold && horizontalDistance > verticalDistance * 2 {
                        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                        impactFeedback.impactOccurred()
                        
                        if value.translation.width > threshold {
                            // 右滑 - 前一个月
                            let (prevYear, prevMonth) = previousMonthData(year: currentYear, month: currentMonth)
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
                            let (nextYear, nextMonth) = nextMonthData(year: currentYear, month: currentMonth)
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
            VStack {
                if showBoundaryMessage {
                    Text(boundaryMessage)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.black.opacity(0.8))
                        )
                        .transition(.opacity.combined(with: .scale))
                        .offset(y: -60)
                }
            }
        )
    }
    
    private func previousMonth() {
        let (prevYear, prevMonth) = previousMonthData(year: currentYear, month: currentMonth)
        if canSwitchToMonth(year: prevYear, month: prevMonth) {
            withAnimation(.spring()) {
                currentYear = prevYear
                currentMonth = prevMonth
            }
        } else {
            showBoundaryAlert("已经是最早的数据月份了")
        }
    }
    
    private func nextMonth() {
        let (nextYear, nextMonth) = nextMonthData(year: currentYear, month: currentMonth)
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
                    VStack(alignment: .leading, spacing: 6) {
                        Text(dayRecord.date)
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(.primary)
                        
                        HStack(spacing: 8) {
                            Text("\(dayRecord.expenses.count) 笔")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.brandPrimary.opacity(0.1))
                                )
                            
                            Text("消费")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 6) {
                        Text("¥\(dayRecord.total)")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(Color.brandPrimary)
                        
                        HStack(spacing: 6) {
                            Text(isExpanded ? "收起" : "展开")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.secondary)
                            
                            Image(systemName: isExpanded ? "chevron.up.circle.fill" : "chevron.down.circle.fill")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color.brandSecondary)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
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
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(isExpanded ? 0.15 : 0.08), radius: isExpanded ? 20 : 12, x: 0, y: isExpanded ? 8 : 6)
                
                // 添加顶部高光效果
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [.white.opacity(0.3), .clear],
                            startPoint: .top,
                            endPoint: UnitPoint(x: 0.5, y: 0.3)
                        )
                    )
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    LinearGradient(
                        colors: isExpanded ? 
                            [Color.brandPrimary.opacity(0.6), Color.brandSecondary.opacity(0.4)] : 
                            [.primary.opacity(0.2), .clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: isExpanded ? 2 : 1
                )
        )
        .scaleEffect(isExpanded ? 1.03 : 1.0)
        .rotation3DEffect(
            .degrees(isExpanded ? 2 : 0),
            axis: (x: 1, y: 0, z: 0),
            perspective: 0.8
        )
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isExpanded)
    }
}

struct MonthlyExpenseRowView: View {
    let expense: Expense
    let dataManager: ExpenseDataManager
    @State private var showingDeleteAlert = false
    
    var body: some View {
        HStack {
            // Category color bar
            Rectangle()
                .fill(Color.categoryColor(for: expense.category))
                .frame(width: 3)
                .clipShape(RoundedRectangle(cornerRadius: 1.5))
            
            HStack(spacing: 12) {
                Image(systemName: expense.categoryIcon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color.categoryColor(for: expense.category))
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
        .padding(.horizontal, 16)
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
                        VStack(spacing: 6) {
                            Text("¥\(monthlyTotal)")
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                            Text("本月支出")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.white.opacity(0.9))
                        }
                        .frame(minHeight: 50)
                        
                        if dataManager.monthlyBudget > 0 {
                            Rectangle()
                                .fill(.white.opacity(0.3))
                                .frame(width: 1, height: 45)
                            
                            VStack(spacing: 6) {
                                Text("¥\(Int(dataManager.monthlyBudget - Double(monthlyTotal)))")
                                    .font(.system(size: 22, weight: .bold, design: .rounded))
                                    .foregroundColor(Double(monthlyTotal) > dataManager.monthlyBudget ? .red : .white)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                                Text("预算余额")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.white.opacity(0.9))
                            }
                            .frame(minHeight: 50)
                        } else {
                            Rectangle()
                                .fill(.white.opacity(0.3))
                                .frame(width: 1, height: 45)
                            
                            VStack(spacing: 6) {
                                Text("\(Int(Double(monthlyTotal) / 30))")
                                    .font(.system(size: 22, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                                Text("日均支出")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.white.opacity(0.9))
                            }
                            .frame(minHeight: 50)
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
            .padding(.top, isCollapsed ? 60 : 100)
            .padding(.bottom, isCollapsed ? 20 : 40)
            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: isCollapsed)
        }
        .frame(height: isCollapsed ? 120 : 220)
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

// Search and Filter Section
struct SearchAndFilterSection: View {
    @Binding var searchText: String
    @Binding var selectedCategoryFilter: String
    @Binding var showingFilterOptions: Bool
    let dataManager: ExpenseDataManager
    
    private let allCategories = [
        ("all", "line.horizontal.3.decrease.circle", "全部"),
        ("food", "fork.knife", "餐饮"),
        ("transport", "car", "交通"),
        ("entertainment", "tv", "娱乐"),
        ("shopping", "bag", "购物"),
        ("medical", "cross", "医疗"),
        ("gift", "gift", "人情"),
        ("bills", "lightbulb", "缴费"),
        ("other", "shippingbox", "其他")
    ]
    
    var body: some View {
        VStack(spacing: 12) {
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                    .font(.system(size: 16))
                
                TextField("搜索支出描述或分类...", text: $searchText)
                    .font(.system(size: 16))
                    .textFieldStyle(PlainTextFieldStyle())
                
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                            .font(.system(size: 16))
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.adaptiveSecondaryBackground)
                    
                    // 内阴影效果
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            LinearGradient(
                                colors: [Color.brandPrimary.opacity(0.08), .clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                        .blur(radius: 0.5)
                }
            )
            .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
            .padding(.horizontal, 16)
            
            // Filter Categories (Horizontal Scroll)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(allCategories, id: \.0) { category in
                        FilterCategoryButton(
                            categoryId: category.0,
                            icon: category.1,
                            title: category.2,
                            isSelected: selectedCategoryFilter == category.0
                        ) {
                            withAnimation(.spring()) {
                                selectedCategoryFilter = category.0
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .padding(.vertical, 16)
        .background(
            ZStack {
                // 主背景卡片
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                
                // 渐变叠加
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.15, green: 0.5, blue: 0.6).opacity(0.03),
                                Color(red: 0.1, green: 0.4, blue: 0.5).opacity(0.02)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    LinearGradient(
                        colors: [Color.brandPrimary.opacity(0.1), Color.brandSecondary.opacity(0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 4)
        .shadow(color: Color.brandPrimary.opacity(0.04), radius: 15, x: 0, y: 6)
    }
}

struct FilterCategoryButton: View {
    let categoryId: String
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(isSelected ? .white : Color.categoryColor(for: categoryId))
                
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(isSelected ? .white : .primary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            isSelected ? 
                                Color.categoryColor(for: categoryId) :
                                Color.categoryColor(for: categoryId).opacity(0.1)
                        )
                    
                    // 添加内阴影效果
                    if isSelected {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(
                                LinearGradient(
                                    colors: [.white.opacity(0.3), .clear],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    }
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        Color.categoryColor(for: categoryId).opacity(isSelected ? 1.0 : 0.3),
                        lineWidth: isSelected ? 1.5 : 1
                    )
            )
            .shadow(
                color: isSelected ? Color.categoryColor(for: categoryId).opacity(0.3) : .clear,
                radius: isSelected ? 8 : 0,
                x: 0,
                y: isSelected ? 4 : 0
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

// Trend Charts Section
struct TrendChartsSection: View {
    let currentMonth: Int
    let currentYear: Int
    let dataManager: ExpenseDataManager
    @State private var animateCharts = false
    
    private var chartData: [DailyExpenseData] {
        let calendar = Calendar.current
        let startOfMonth = calendar.date(from: DateComponents(year: currentYear, month: currentMonth, day: 1))!
        let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth)!
        
        let monthlyExpenses = dataManager.expenses.filter { expense in
            expense.date >= startOfMonth && expense.date <= endOfMonth
        }
        
        let groupedByDay = Dictionary(grouping: monthlyExpenses) { expense in
            calendar.component(.day, from: expense.date)
        }
        
        var chartData: [DailyExpenseData] = []
        let daysInMonth = calendar.range(of: .day, in: .month, for: startOfMonth)?.count ?? 30
        
        for day in 1...daysInMonth {
            let expenses = groupedByDay[day] ?? []
            let total = expenses.reduce(0) { $0 + $1.amount }
            chartData.append(DailyExpenseData(day: day, amount: total))
        }
        
        return chartData
    }
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("支出趋势")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("单位：元")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            
            VStack(spacing: 16) {
                // Bar Chart
                VStack(alignment: .leading, spacing: 12) {
                    Text("日支出柱状图")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.secondary)
                    
                    DailyBarChart(data: chartData, animate: animateCharts)
                        .frame(height: 120)
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.adaptiveSecondaryBackground)
                )
                
                // Line Chart  
                VStack(alignment: .leading, spacing: 12) {
                    Text("支出趋势线图")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.secondary)
                    
                    DailyLineChart(data: chartData, animate: animateCharts)
                        .frame(height: 120)
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.adaptiveSecondaryBackground)
                )
            }
        }
        .padding(.horizontal, 20)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0).delay(0.3)) {
                animateCharts = true
            }
        }
        .onChange(of: currentMonth) { _ in
            animateCharts = false
            withAnimation(.easeInOut(duration: 0.8).delay(0.2)) {
                animateCharts = true
            }
        }
        .onChange(of: currentYear) { _ in
            animateCharts = false
            withAnimation(.easeInOut(duration: 0.8).delay(0.2)) {
                animateCharts = true
            }
        }
    }
}

// Data structure for charts
struct DailyExpenseData {
    let day: Int
    let amount: Double
}

// Bar Chart Component
struct DailyBarChart: View {
    let data: [DailyExpenseData]
    let animate: Bool
    
    private var maxAmount: Double {
        data.map { $0.amount }.max() ?? 0
    }
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 1) {
            ForEach(data.indices, id: \.self) { index in
                let item = data[index]
                VStack(spacing: 2) {
                    // Bar
                    RoundedRectangle(cornerRadius: 2)
                        .fill(
                            LinearGradient(
                                colors: [Color.brandPrimary.opacity(0.8), Color.brandSecondary.opacity(0.6)],
                                startPoint: .bottom,
                                endPoint: .top
                            )
                        )
                        .frame(
                            width: max(2, (UIScreen.main.bounds.width - 120) / CGFloat(data.count)),
                            height: animate ? 
                                CGFloat((item.amount / (maxAmount > 0 ? maxAmount : 1)) * 100) : 0
                        )
                        .opacity(item.amount > 0 ? 1.0 : 0.1)
                    
                    // Day label (only show every 5 days to avoid crowding)
                    if item.day % 5 == 1 || item.day == data.count {
                        Text("\(item.day)")
                            .font(.system(size: 8))
                            .foregroundColor(.secondary)
                    } else {
                        Text("")
                            .font(.system(size: 8))
                    }
                }
                .animation(.easeInOut(duration: 0.8).delay(Double(index) * 0.02), value: animate)
            }
        }
        .padding(.bottom, 20)
    }
}

// Line Chart Component
struct DailyLineChart: View {
    let data: [DailyExpenseData]
    let animate: Bool
    
    private var maxAmount: Double {
        data.map { $0.amount }.max() ?? 0
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Grid lines
                VStack(spacing: 0) {
                    ForEach(0..<5) { _ in
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 0.5)
                        Spacer()
                    }
                }
                
                // Line path
                Path { path in
                    let width = geometry.size.width
                    let height = geometry.size.height - 20
                    let stepX = width / CGFloat(data.count - 1)
                    
                    for (index, item) in data.enumerated() {
                        let x = CGFloat(index) * stepX
                        let y = height - CGFloat((item.amount / (maxAmount > 0 ? maxAmount : 1)) * Double(height))
                        
                        if index == 0 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                }
                .trim(from: 0, to: animate ? 1 : 0)
                .stroke(
                    LinearGradient(
                        colors: [Color.brandTertiary, Color.brandPrimary],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)
                )
                .animation(.easeInOut(duration: 1.5), value: animate)
                
                // Data points
                ForEach(data.indices, id: \.self) { index in
                    let item = data[index]
                    let width = geometry.size.width
                    let height = geometry.size.height - 20
                    let stepX = width / CGFloat(data.count - 1)
                    let x = CGFloat(index) * stepX
                    let y = height - CGFloat((item.amount / (maxAmount > 0 ? maxAmount : 1)) * Double(height))
                    
                    Circle()
                        .fill(Color.brandAccent)
                        .frame(width: item.amount > 0 ? 6 : 3, height: item.amount > 0 ? 6 : 3)
                        .position(x: x, y: y)
                        .opacity(animate ? 1 : 0)
                        .scaleEffect(animate ? 1 : 0)
                        .animation(.easeInOut(duration: 0.5).delay(Double(index) * 0.05), value: animate)
                }
            }
        }
        .padding(.bottom, 20)
    }
}

// Preference key for tracking scroll offset
struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

