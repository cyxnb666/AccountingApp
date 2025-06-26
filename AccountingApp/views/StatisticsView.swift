// StatisticsView.swift
import SwiftUI

enum TimePeriod: String, CaseIterable {
    case monthly = "月度"
    case weekly = "周度"
}

struct StatisticsView: View {
    @EnvironmentObject var dataManager: ExpenseDataManager
    @State private var animateCards = false
    @State private var animateChart = false
    @State private var selectedMonth = Calendar.current.component(.month, from: Date())
    @State private var selectedYear = Calendar.current.component(.year, from: Date())
    @State private var boundaryMessage: String = ""
    @State private var showBoundaryMessage = false
    @State private var selectedTimePeriod: TimePeriod = .monthly
    @State private var selectedWeekOffset: Int = 0
    
    // Helper function to get category ID from name
    private func getCategoryId(from name: String) -> String {
        switch name {
        case "餐饮": return "food"
        case "交通": return "transport"
        case "娱乐": return "entertainment"
        case "购物": return "shopping"
        case "医疗": return "medical"
        case "人情": return "gift"
        case "缴费": return "bills"
        default: return "other"
        }
    }
    
    private var currentWeekStart: Date {
        let calendar = Calendar.current
        let today = Date()
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: today)?.start ?? today
        return calendar.date(byAdding: .weekOfYear, value: selectedWeekOffset, to: weekStart) ?? weekStart
    }
    
    private var currentWeekEnd: Date {
        let calendar = Calendar.current
        return calendar.date(byAdding: .day, value: 6, to: currentWeekStart) ?? currentWeekStart
    }
    
    private var monthlyStats: MonthlyStats {
        let calendar = Calendar.current
        let (startDate, endDate, period, budget): (Date, Date, Int, Double)
        
        if selectedTimePeriod == .monthly {
            let startOfMonth = calendar.date(from: DateComponents(year: selectedYear, month: selectedMonth, day: 1))!
            let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth)!
            let daysInMonth = calendar.range(of: .day, in: .month, for: startOfMonth)?.count ?? 30
            startDate = startOfMonth
            endDate = endOfMonth
            period = daysInMonth
            budget = dataManager.monthlyBudget
        } else {
            startDate = currentWeekStart
            endDate = currentWeekEnd
            period = 7
            budget = dataManager.monthlyBudget / 4.0 // 周预算为月预算的1/4
        }
        
        let periodExpenses = dataManager.expenses.filter { expense in
            expense.date >= startDate && expense.date <= endDate
        }
        
        let totalExpense = periodExpenses.reduce(0) { $0 + $1.amount }
        let recordCount = periodExpenses.count
        let dailyAverage = recordCount > 0 ? totalExpense / Double(period) : 0
        let averagePerRecord = recordCount > 0 ? totalExpense / Double(recordCount) : 0
        let budgetUsed = budget > 0 ? (totalExpense / budget) * 100 : 0
        
        return MonthlyStats(
            totalExpense: totalExpense,
            dailyAverage: dailyAverage,
            recordCount: recordCount,
            averagePerRecord: averagePerRecord,
            budget: budget,
            budgetUsed: budgetUsed
        )
    }
    
    private var categoryStats: [CategoryStat] {
        let (startDate, endDate): (Date, Date)
        
        if selectedTimePeriod == .monthly {
            let calendar = Calendar.current
            let startOfMonth = calendar.date(from: DateComponents(year: selectedYear, month: selectedMonth, day: 1))!
            let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth)!
            startDate = startOfMonth
            endDate = endOfMonth
        } else {
            startDate = currentWeekStart
            endDate = currentWeekEnd
        }
        
        let periodExpenses = dataManager.expenses.filter { expense in
            expense.date >= startDate && expense.date <= endDate
        }
        
        let totalAmount = periodExpenses.reduce(0) { $0 + $1.amount }
        
        let categoryGroups = Dictionary(grouping: periodExpenses) { $0.category }
        
        let stats = categoryGroups.map { (category, expenses) in
            let amount = expenses.reduce(0) { $0 + $1.amount }
            let percentage = totalAmount > 0 ? Int((amount / totalAmount) * 100) : 0
            let categoryName = expenses.first?.categoryName ?? "其他"
            let categoryIcon = expenses.first?.categoryIcon ?? "shippingbox"
            
            return CategoryStat(
                name: categoryName,
                icon: categoryIcon,
                amount: Int(amount),
                percentage: percentage
            )
        }.sorted { $0.amount > $1.amount }
        
        return stats
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
        ScrollView {
            VStack(spacing: 0) {
                // Header
                StatisticsHeaderView()
                    .ignoresSafeArea(.all, edges: .top)
                
                // Time Period Selector
                TimePeriodSelectorView(
                    selectedTimePeriod: $selectedTimePeriod,
                    selectedMonth: $selectedMonth,
                    selectedYear: $selectedYear,
                    selectedWeekOffset: $selectedWeekOffset,
                    currentWeekStart: currentWeekStart,
                    currentWeekEnd: currentWeekEnd
                )
                .environmentObject(dataManager)
                
                VStack(spacing: 20) {
                    // Budget Overview
                    if monthlyStats.budget > 0 {
                        BudgetOverviewView(
                            stats: monthlyStats,
                            animate: animateCards
                        )
                    }
                    
                    // Monthly Summary
                    MonthlySummaryView(
                        stats: monthlyStats, 
                        animate: animateCards,
                        selectedMonth: selectedMonth,
                        selectedYear: selectedYear,
                        selectedTimePeriod: selectedTimePeriod,
                        currentWeekStart: currentWeekStart,
                        currentWeekEnd: currentWeekEnd
                    )
                    
                    // Category Statistics
                    CategoryStatisticsView(
                        categories: categoryStats,
                        animate: animateChart
                    )
                    
                    // Trend Comparison
                    TrendComparisonView(
                        selectedMonth: selectedMonth,
                        selectedYear: selectedYear,
                        selectedTimePeriod: selectedTimePeriod,
                        currentWeekStart: currentWeekStart,
                        currentWeekEnd: currentWeekEnd
                    )
                    .environmentObject(dataManager)
                    
                    // Trend Chart
                    TrendChartView(
                        selectedMonth: selectedMonth,
                        selectedYear: selectedYear,
                        selectedTimePeriod: selectedTimePeriod,
                        currentWeekStart: currentWeekStart,
                        currentWeekEnd: currentWeekEnd
                    )
                }
                .padding(.top, 20)
                .padding(.bottom, 100) // Space for tab bar
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
        .onAppear {
            withAnimation(.easeInOut(duration: 0.8).delay(0.2)) {
                animateCards = true
            }
            withAnimation(.easeInOut(duration: 1.0).delay(0.5)) {
                animateChart = true
            }
        }
        .onChange(of: selectedMonth) { _ in
            // 重新触发动画
            animateCards = false
            animateChart = false
            withAnimation(.easeInOut(duration: 0.6).delay(0.1)) {
                animateCards = true
            }
            withAnimation(.easeInOut(duration: 0.8).delay(0.3)) {
                animateChart = true
            }
        }
        .onChange(of: selectedYear) { _ in
            // 重新触发动画
            animateCards = false
            animateChart = false
            withAnimation(.easeInOut(duration: 0.6).delay(0.1)) {
                animateCards = true
            }
            withAnimation(.easeInOut(duration: 0.8).delay(0.3)) {
                animateChart = true
            }
        }
    }
}

struct StatisticsHeaderView: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.6, green: 0.3, blue: 0.7),
                    Color(red: 0.5, green: 0.2, blue: 0.6)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            VStack(spacing: 12) {
                Text("支出统计")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text("了解您的消费习惯")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
            }
            .padding(.top, 100)
            .padding(.bottom, 40)
        }
        .frame(height: 220)
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

struct BudgetOverviewView: View {
    let stats: MonthlyStats
    let animate: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("预算概览")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("¥\(Int(stats.budget - stats.totalExpense))")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(stats.totalExpense > stats.budget ? .red : .green)
            }
            
            VStack(spacing: 12) {
                HStack {
                    Text("已用")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("¥\(Int(stats.totalExpense))")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                }
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(.systemGray5))
                            .frame(height: 12)
                        
                        RoundedRectangle(cornerRadius: 8)
                            .fill(
                                LinearGradient(
                                    colors: stats.totalExpense > stats.budget ? 
                                        [.red, .orange] : [.blue, .green],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(
                                width: animate ? 
                                    min(geometry.size.width * CGFloat(stats.budgetUsed / 100), geometry.size.width) : 0,
                                height: 12
                            )
                            .animation(.easeInOut(duration: 1.0), value: animate)
                    }
                }
                .frame(height: 12)
                
                HStack {
                    Text("预算 ¥\(Int(stats.budget))")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(Int(stats.budgetUsed))%")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(stats.totalExpense > stats.budget ? .red : .blue)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.05), radius: 15, x: 0, y: 8)
        )
        .padding(.horizontal, 20)
    }
}

struct TimePeriodSelectorView: View {
    @EnvironmentObject var dataManager: ExpenseDataManager
    @Binding var selectedTimePeriod: TimePeriod
    @Binding var selectedMonth: Int
    @Binding var selectedYear: Int
    @Binding var selectedWeekOffset: Int
    let currentWeekStart: Date
    let currentWeekEnd: Date
    
    private var weekDateRange: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM月dd日"
        formatter.locale = Locale(identifier: "zh_CN")
        
        let startString = formatter.string(from: currentWeekStart)
        let endString = formatter.string(from: currentWeekEnd)
        
        return "\(startString) - \(endString)"
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Time Period Picker
            HStack {
                ForEach(TimePeriod.allCases, id: \.self) { period in
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedTimePeriod = period
                        }
                    }) {
                        Text(period.rawValue)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(selectedTimePeriod == period ? .white : .secondary)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(selectedTimePeriod == period ? 
                                        LinearGradient(colors: [.purple, .blue], startPoint: .leading, endPoint: .trailing) :
                                        LinearGradient(colors: [.clear], startPoint: .leading, endPoint: .trailing)
                                    )
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 20)
            
            // Date Navigation
            if selectedTimePeriod == .monthly {
                MonthSelectorView(
                    currentMonth: $selectedMonth,
                    currentYear: $selectedYear
                )
            } else {
                WeekSelectorView(
                    selectedWeekOffset: $selectedWeekOffset,
                    weekDateRange: weekDateRange
                )
            }
        }
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
        )
        .padding(.horizontal, 20)
        .padding(.top, 0)
    }
}

struct WeekSelectorView: View {
    @Binding var selectedWeekOffset: Int
    let weekDateRange: String
    
    var body: some View {
        HStack {
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    selectedWeekOffset -= 1
                }
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.primary)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(.ultraThinMaterial)
                            .overlay(
                                Circle()
                                    .stroke(.white.opacity(0.2), lineWidth: 1)
                            )
                    )
            }
            .buttonStyle(PlainButtonStyle())
            
            Spacer()
            
            VStack(spacing: 4) {
                Text(selectedWeekOffset == 0 ? "本周" : "第\(abs(selectedWeekOffset))周\(selectedWeekOffset > 0 ? "后" : "前")")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.primary)
                
                Text(weekDateRange)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    selectedWeekOffset += 1
                }
            }) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.primary)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(.ultraThinMaterial)
                            .overlay(
                                Circle()
                                    .stroke(.white.opacity(0.2), lineWidth: 1)
                            )
                    )
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 20)
    }
}

struct MonthlySummaryView: View {
    let stats: MonthlyStats
    let animate: Bool
    let selectedMonth: Int
    let selectedYear: Int
    let selectedTimePeriod: TimePeriod
    let currentWeekStart: Date
    let currentWeekEnd: Date
    
    private var periodTitle: String {
        if selectedTimePeriod == .monthly {
            return "\(selectedYear)年\(selectedMonth)月概览"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MM月dd日"
            formatter.locale = Locale(identifier: "zh_CN")
            
            let startString = formatter.string(from: currentWeekStart)
            let endString = formatter.string(from: currentWeekEnd)
            
            return "\(startString) - \(endString) 概览"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text(periodTitle)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.primary)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 15) {
                StatCard(
                    title: selectedTimePeriod == .monthly ? "月度支出" : "周度支出",
                    value: stats.totalExpense >= 10000 ? 
                        String(format: "¥%.1fw", stats.totalExpense / 10000) :
                        "¥\(Int(stats.totalExpense))",
                    color: Color.blue,
                    animate: animate
                )
                .animation(.easeInOut.delay(0.1), value: animate)
                
                StatCard(
                    title: "日均支出",
                    value: String(format: "¥%.1f", stats.dailyAverage),
                    color: Color.green,
                    animate: animate
                )
                .animation(.easeInOut.delay(0.2), value: animate)
                
                StatCard(
                    title: "记账笔数",
                    value: "\(stats.recordCount)",
                    color: Color.orange,
                    animate: animate
                )
                .animation(.easeInOut.delay(0.3), value: animate)
                
                StatCard(
                    title: "平均每笔",
                    value: String(format: "¥%.1f", stats.averagePerRecord),
                    color: Color.purple,
                    animate: animate
                )
                .animation(.easeInOut.delay(0.4), value: animate)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.05), radius: 15, x: 0, y: 8)
        )
        .padding(.horizontal, 20)
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let color: Color
    let animate: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(color)
                .scaleEffect(animate ? 1.0 : 0.5)
                .opacity(animate ? 1.0 : 0.0)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(color.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

struct CategoryStatisticsView: View {
    let categories: [CategoryStat]
    let animate: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("分类统计")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.primary)
            
            if categories.isEmpty {
                VStack {
                    Image(systemName: "chart.pie")
                        .font(.system(size: 48))
                        .foregroundColor(.gray.opacity(0.6))
                    
                    Text("暂无支出数据")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 150)
            } else {
                VStack(spacing: 16) {
                    ForEach(Array(categories.enumerated()), id: \.offset) { index, category in
                        CategoryStatRow(
                            category: category,
                            animate: animate
                        )
                        .animation(.easeInOut.delay(Double(index) * 0.1), value: animate)
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.05), radius: 15, x: 0, y: 8)
        )
        .padding(.horizontal, 20)
    }
}

struct CategoryStatRow: View {
    let category: CategoryStat
    let animate: Bool
    
    // Helper function to get category ID from name
    private func getCategoryId(from name: String) -> String {
        switch name {
        case "餐饮": return "food"
        case "交通": return "transport"
        case "娱乐": return "entertainment"
        case "购物": return "shopping"
        case "医疗": return "medical"
        case "人情": return "gift"
        case "缴费": return "bills"
        default: return "other"
        }
    }
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                // Icon and Name
                HStack(spacing: 12) {
                    Image(systemName: category.icon)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(Color.categoryColor(for: getCategoryId(from: category.name)))
                        .frame(width: 40, height: 40)
                        .background(
                            Circle()
                                .fill(Color.categoryColor(for: getCategoryId(from: category.name)).opacity(0.1))
                        )
                    
                    Text(category.name)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                // Amount and Percentage
                VStack(alignment: .trailing, spacing: 2) {
                    Text("¥\(category.amount)")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.blue)
                    
                    Text("\(category.percentage)%")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            
            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray5))
                        .frame(height: 6)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(
                            width: animate ?
                                geometry.size.width * (CGFloat(category.percentage) / 100) : 0,
                            height: 6
                        )
                        .animation(.easeInOut(duration: 1.0), value: animate)
                }
            }
            .frame(height: 6)
        }
        .padding(.vertical, 8)
    }
}

enum ChartType: String, CaseIterable {
    case pie = "饼图"
    case bar = "柱状图"
    case line = "折线图"
}

struct TrendChartView: View {
    @EnvironmentObject var dataManager: ExpenseDataManager
    @State private var animatePie = false
    @State private var selectedChartType: ChartType = .pie
    let selectedMonth: Int
    let selectedYear: Int
    let selectedTimePeriod: TimePeriod
    let currentWeekStart: Date
    let currentWeekEnd: Date
    
    var pieData: [PieSliceData] {
        let (startDate, endDate): (Date, Date)
        
        if selectedTimePeriod == .monthly {
            let calendar = Calendar.current
            let startOfMonth = calendar.date(from: DateComponents(year: selectedYear, month: selectedMonth, day: 1))!
            let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth)!
            startDate = startOfMonth
            endDate = endOfMonth
        } else {
            startDate = currentWeekStart
            endDate = currentWeekEnd
        }
        
        let periodExpenses = dataManager.expenses.filter { expense in
            expense.date >= startDate && expense.date <= endDate
        }
        
        let categoryGroups = Dictionary(grouping: periodExpenses) { $0.category }
        let colors: [Color] = [.blue, .green, .orange, .purple, .pink, .red, .yellow, .cyan]
        
        return categoryGroups.enumerated().map { index, item in
            let (_, expenses) = item
            let amount = expenses.reduce(0) { $0 + Int($1.amount) }
            let categoryName = expenses.first?.categoryName ?? "其他"
            
            return PieSliceData(
                category: categoryName,
                value: amount,
                color: colors[index % colors.count]
            )
        }.sorted { $0.value > $1.value }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("支出分布")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                // Chart Type Selector
                HStack(spacing: 8) {
                    ForEach(ChartType.allCases, id: \.self) { chartType in
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedChartType = chartType
                            }
                        }) {
                            Text(chartType.rawValue)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(selectedChartType == chartType ? .white : .secondary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(selectedChartType == chartType ? 
                                            LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing) :
                                            LinearGradient(colors: [.clear], startPoint: .leading, endPoint: .trailing)
                                        )
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            
            if pieData.isEmpty {
                VStack {
                    Image(systemName: "chart.pie")
                        .font(.system(size: 48))
                        .foregroundColor(.gray.opacity(0.6))
                    
                    Text("暂无数据")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 180)
            } else {
                Group {
                    switch selectedChartType {
                    case .pie:
                        HStack(spacing: 20) {
                            // Pie Chart
                            ZStack {
                                PieChart(
                                    data: pieData, 
                                    animate: animatePie
                                )
                                .frame(width: 160, height: 160)
                                
                                VStack(spacing: 2) {
                                    Text("总支出")
                                        .font(.system(size: 12))
                                        .foregroundColor(.secondary)
                                    Text("¥\(pieData.reduce(0) { $0 + $1.value })")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(.primary)
                                }
                            }
                            
                            // Legend
                            VStack(alignment: .leading, spacing: 12) {
                                ForEach(pieData.prefix(5), id: \.category) { slice in
                                    HStack(spacing: 8) {
                                        Circle()
                                            .fill(slice.color)
                                            .frame(width: 12, height: 12)
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(slice.category)
                                                .font(.system(size: 14, weight: .medium))
                                                .foregroundColor(.primary)
                                            
                                            Text("¥\(slice.value)")
                                                .font(.system(size: 12))
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        Spacer()
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity)
                        }
                        
                    case .bar:
                        BarChartView(data: pieData)
                        
                    case .line:
                        LineChartView(data: pieData)
                    }
                }
                .frame(height: 180)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.05), radius: 15, x: 0, y: 8)
        )
        .padding(.horizontal, 20)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).delay(0.3)) {
                animatePie = true
            }
        }
        .onChange(of: selectedMonth) { _ in
            animatePie = false
            withAnimation(.easeInOut(duration: 1.0).delay(0.2)) {
                animatePie = true
            }
        }
        .onChange(of: selectedYear) { _ in
            animatePie = false
            withAnimation(.easeInOut(duration: 1.0).delay(0.2)) {
                animatePie = true
            }
        }
    }
}

// Data Models
struct MonthlyStats {
    let totalExpense: Double
    let dailyAverage: Double
    let recordCount: Int
    let averagePerRecord: Double
    let budget: Double
    let budgetUsed: Double
}

struct CategoryStat {
    let name: String
    let icon: String
    let amount: Int
    let percentage: Int
}

// Pie Chart Data Structure
struct PieSliceData {
    let category: String
    let value: Int
    let color: Color
}

// Pie Chart Component
struct PieChart: View {
    let data: [PieSliceData]
    let animate: Bool
    
    var body: some View {
        ZStack {
            ForEach(Array(data.enumerated()), id: \.offset) { index, slice in
                PieSlice(
                    startAngle: startAngle(for: index),
                    endAngle: endAngle(for: index),
                    color: slice.color,
                    animate: animate
                )
            }
        }
    }
    
    private var totalValue: Int {
        data.reduce(0) { $0 + $1.value }
    }
    
    private func startAngle(for index: Int) -> Angle {
        let sum = data.prefix(index).reduce(0) { $0 + $1.value }
        return Angle(degrees: Double(sum) / Double(totalValue) * 360 - 90)
    }
    
    private func endAngle(for index: Int) -> Angle {
        let sum = data.prefix(index + 1).reduce(0) { $0 + $1.value }
        return Angle(degrees: Double(sum) / Double(totalValue) * 360 - 90)
    }
}

// Individual Pie Slice
struct PieSlice: View {
    let startAngle: Angle
    let endAngle: Angle
    let color: Color
    let animate: Bool
    
    var body: some View {
        Path { path in
            let center = CGPoint(x: 80, y: 80)
            let radius: CGFloat = 70
            
            path.move(to: center)
            path.addArc(
                center: center,
                radius: radius,
                startAngle: startAngle,
                endAngle: animate ? endAngle : startAngle,
                clockwise: false
            )
            path.closeSubpath()
        }
        .fill(color)
        .animation(.easeInOut(duration: 1.0), value: animate)
    }
}


// Trend Comparison View
struct TrendComparisonView: View {
    @EnvironmentObject var dataManager: ExpenseDataManager
    let selectedMonth: Int
    let selectedYear: Int
    let selectedTimePeriod: TimePeriod
    let currentWeekStart: Date
    let currentWeekEnd: Date
    
    private func getCurrentPeriodAmount() -> Double {
        let (startDate, endDate): (Date, Date)
        
        if selectedTimePeriod == .monthly {
            let calendar = Calendar.current
            let startOfMonth = calendar.date(from: DateComponents(year: selectedYear, month: selectedMonth, day: 1))!
            let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth)!
            startDate = startOfMonth
            endDate = endOfMonth
        } else {
            startDate = currentWeekStart
            endDate = currentWeekEnd
        }
        
        return dataManager.expenses.filter { expense in
            expense.date >= startDate && expense.date <= endDate
        }.reduce(0) { $0 + $1.amount }
    }
    
    private func getLastPeriodAmount() -> Double {
        let calendar = Calendar.current
        let (startDate, endDate): (Date, Date)
        
        if selectedTimePeriod == .monthly {
            let currentMonthStart = calendar.date(from: DateComponents(year: selectedYear, month: selectedMonth, day: 1))!
            let lastMonthStart = calendar.date(byAdding: .month, value: -1, to: currentMonthStart)!
            let lastMonthEnd = calendar.date(byAdding: .day, value: -1, to: currentMonthStart)!
            startDate = lastMonthStart
            endDate = lastMonthEnd
        } else {
            let lastWeekStart = calendar.date(byAdding: .weekOfYear, value: -1, to: currentWeekStart)!
            let lastWeekEnd = calendar.date(byAdding: .day, value: 6, to: lastWeekStart)!
            startDate = lastWeekStart
            endDate = lastWeekEnd
        }
        
        return dataManager.expenses.filter { expense in
            expense.date >= startDate && expense.date <= endDate
        }.reduce(0) { $0 + $1.amount }
    }
    
    private func getYearOverYearAmount() -> Double {
        let calendar = Calendar.current
        let (startDate, endDate): (Date, Date)
        
        if selectedTimePeriod == .monthly {
            let currentMonthStart = calendar.date(from: DateComponents(year: selectedYear, month: selectedMonth, day: 1))!
            let lastYearStart = calendar.date(from: DateComponents(year: selectedYear - 1, month: selectedMonth, day: 1))!
            let lastYearEnd = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: lastYearStart)!
            startDate = lastYearStart
            endDate = lastYearEnd
        } else {
            let lastYearWeekStart = calendar.date(byAdding: .year, value: -1, to: currentWeekStart)!
            let lastYearWeekEnd = calendar.date(byAdding: .day, value: 6, to: lastYearWeekStart)!
            startDate = lastYearWeekStart
            endDate = lastYearWeekEnd
        }
        
        return dataManager.expenses.filter { expense in
            expense.date >= startDate && expense.date <= endDate
        }.reduce(0) { $0 + $1.amount }
    }
    
    private var monthOverMonthChange: (percentage: Double, isIncrease: Bool) {
        let current = getCurrentPeriodAmount()
        let last = getLastPeriodAmount()
        
        guard last > 0 else { return (0, false) }
        
        let change = ((current - last) / last) * 100
        return (abs(change), change > 0)
    }
    
    private var yearOverYearChange: (percentage: Double, isIncrease: Bool) {
        let current = getCurrentPeriodAmount()
        let lastYear = getYearOverYearAmount()
        
        guard lastYear > 0 else { return (0, false) }
        
        let change = ((current - lastYear) / lastYear) * 100
        return (abs(change), change > 0)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("趋势对比")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.primary)
            
            HStack(spacing: 16) {
                // 环比
                VStack(spacing: 12) {
                    Text(selectedTimePeriod == .monthly ? "环比" : "周环比")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 4) {
                        Image(systemName: monthOverMonthChange.isIncrease ? "arrow.up" : "arrow.down")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(monthOverMonthChange.isIncrease ? .red : .green)
                        
                        Text(String(format: "%.1f%%", monthOverMonthChange.percentage))
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(monthOverMonthChange.isIncrease ? .red : .green)
                    }
                    
                    Text("较上\(selectedTimePeriod == .monthly ? "月" : "周")")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(monthOverMonthChange.isIncrease ? Color.red.opacity(0.3) : Color.green.opacity(0.3), lineWidth: 1)
                        )
                )
                
                // 同比
                VStack(spacing: 12) {
                    Text("同比")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 4) {
                        Image(systemName: yearOverYearChange.isIncrease ? "arrow.up" : "arrow.down")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(yearOverYearChange.isIncrease ? .red : .green)
                        
                        Text(String(format: "%.1f%%", yearOverYearChange.percentage))
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(yearOverYearChange.isIncrease ? .red : .green)
                    }
                    
                    Text("较去年同期")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(yearOverYearChange.isIncrease ? Color.red.opacity(0.3) : Color.green.opacity(0.3), lineWidth: 1)
                        )
                )
            }
            
            // 详细对比数据
            VStack(spacing: 8) {
                HStack {
                    Text("本期支出")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("¥\(Int(getCurrentPeriodAmount()))")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                }
                
                HStack {
                    Text("上期支出")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("¥\(Int(getLastPeriodAmount()))")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                }
                
                HStack {
                    Text("去年同期")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("¥\(Int(getYearOverYearAmount()))")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
            )
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.05), radius: 15, x: 0, y: 8)
        )
        .padding(.horizontal, 20)
    }
}
// Bar Chart View
struct BarChartView: View {
    let data: [PieSliceData]
    @State private var animateBars = false
    
    private var maxValue: Int {
        data.map { $0.value }.max() ?? 1
    }
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 12) {
            ForEach(Array(data.prefix(6).enumerated()), id: \.offset) { index, item in
                VStack(spacing: 8) {
                    Text("¥\(item.value)")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.primary)
                        .opacity(animateBars ? 1 : 0)
                        .animation(.easeInOut.delay(Double(index) * 0.1), value: animateBars)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [item.color, item.color.opacity(0.6)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(
                            width: 30,
                            height: animateBars ? 
                                CGFloat(item.value) / CGFloat(maxValue) * 120 : 0
                        )
                        .animation(.easeInOut(duration: 0.8).delay(Double(index) * 0.1), value: animateBars)
                    
                    Text(item.category)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .frame(width: 35)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .onAppear {
            withAnimation {
                animateBars = true
            }
        }
    }
}

// Line Chart View
struct LineChartView: View {
    let data: [PieSliceData]
    @State private var animateLine = false
    
    private var maxValue: Int {
        data.map { $0.value }.max() ?? 1
    }
    
    var body: some View {
        VStack(spacing: 16) {
            GeometryReader { geometry in
                ZStack {
                    // Grid lines
                    ForEach(0..<5) { i in
                        Path { path in
                            let y = geometry.size.height * CGFloat(i) / 4
                            path.move(to: CGPoint(x: 0, y: y))
                            path.addLine(to: CGPoint(x: geometry.size.width, y: y))
                        }
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    }
                    
                    // Line chart
                    if data.count > 1 {
                        Path { path in
                            let points = data.prefix(6).enumerated().map { index, item in
                                CGPoint(
                                    x: geometry.size.width * CGFloat(index) / CGFloat(min(data.count - 1, 5)),
                                    y: geometry.size.height * (1 - CGFloat(item.value) / CGFloat(maxValue))
                                )
                            }
                            
                            if let firstPoint = points.first {
                                path.move(to: firstPoint)
                                for point in points.dropFirst() {
                                    path.addLine(to: point)
                                }
                            }
                        }
                        .trim(from: 0, to: animateLine ? 1 : 0)
                        .stroke(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)
                        )
                        .animation(.easeInOut(duration: 1.5), value: animateLine)
                        
                        // Data points
                        ForEach(Array(data.prefix(6).enumerated()), id: \.offset) { index, item in
                            Circle()
                                .fill(item.color)
                                .frame(width: 8, height: 8)
                                .position(
                                    x: geometry.size.width * CGFloat(index) / CGFloat(min(data.count - 1, 5)),
                                    y: geometry.size.height * (1 - CGFloat(item.value) / CGFloat(maxValue))
                                )
                                .scaleEffect(animateLine ? 1 : 0)
                                .animation(.easeInOut.delay(Double(index) * 0.1), value: animateLine)
                        }
                    }
                }
            }
            .frame(height: 120)
            
            // Category labels
            HStack {
                ForEach(Array(data.prefix(6).enumerated()), id: \.offset) { index, item in
                    Text(item.category)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .onAppear {
            withAnimation {
                animateLine = true
            }
        }
    }
}
