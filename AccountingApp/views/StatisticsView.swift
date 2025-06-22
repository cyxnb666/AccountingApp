// StatisticsView.swift
import SwiftUI

struct StatisticsView: View {
    @EnvironmentObject var dataManager: ExpenseDataManager
    @State private var animateCards = false
    @State private var animateChart = false
    
    var monthlyStats: MonthlyStats {
        let currentMonth = Calendar.current.component(.month, from: Date())
        let currentYear = Calendar.current.component(.year, from: Date())
        let calendar = Calendar.current
        let startOfMonth = calendar.date(from: DateComponents(year: currentYear, month: currentMonth, day: 1))!
        let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth)!
        
        let monthlyExpenses = dataManager.expenses.filter { expense in
            expense.date >= startOfMonth && expense.date <= endOfMonth
        }
        
        let totalExpense = monthlyExpenses.reduce(0) { $0 + $1.amount }
        let recordCount = monthlyExpenses.count
        let daysInMonth = calendar.range(of: .day, in: .month, for: Date())?.count ?? 30
        let dailyAverage = recordCount > 0 ? totalExpense / Double(daysInMonth) : 0
        let averagePerRecord = recordCount > 0 ? totalExpense / Double(recordCount) : 0
        
        return MonthlyStats(
            totalExpense: totalExpense,
            dailyAverage: dailyAverage,
            recordCount: recordCount,
            averagePerRecord: averagePerRecord
        )
    }
    
    var categoryStats: [CategoryStat] {
        let currentMonth = Calendar.current.component(.month, from: Date())
        let currentYear = Calendar.current.component(.year, from: Date())
        let calendar = Calendar.current
        let startOfMonth = calendar.date(from: DateComponents(year: currentYear, month: currentMonth, day: 1))!
        let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth)!
        
        let monthlyExpenses = dataManager.expenses.filter { expense in
            expense.date >= startOfMonth && expense.date <= endOfMonth
        }
        
        let totalAmount = monthlyExpenses.reduce(0) { $0 + $1.amount }
        
        let categoryGroups = Dictionary(grouping: monthlyExpenses) { $0.category }
        
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
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header
                StatisticsHeaderView()
                
                VStack(spacing: 20) {
                    // Monthly Summary
                    MonthlySummaryView(stats: monthlyStats, animate: animateCards)
                    
                    // Category Statistics
                    CategoryStatisticsView(
                        categories: categoryStats,
                        animate: animateChart
                    )
                    
                    // Trend Chart (Placeholder)
                    TrendChartView()
                }
                .padding(.top, 20)
                .padding(.bottom, 100) // Space for tab bar
            }
        }
        .background(Color(.systemGroupedBackground))
        .onAppear {
            withAnimation(.easeInOut(duration: 0.8).delay(0.2)) {
                animateCards = true
            }
            withAnimation(.easeInOut(duration: 1.0).delay(0.5)) {
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
            
            VStack(spacing: 8) {
                Text("支出统计")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text("了解您的消费习惯")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
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

struct MonthlySummaryView: View {
    let stats: MonthlyStats
    let animate: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("本月概览")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.primary)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 15) {
                StatCard(
                    title: "本月支出",
                    value: "¥\(Int(stats.totalExpense))",
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
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(color)
                .scaleEffect(animate ? 1.0 : 0.5)
                .opacity(animate ? 1.0 : 0.0)
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
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                // Icon and Name
                HStack(spacing: 12) {
                    Image(systemName: category.icon)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.blue)
                        .frame(width: 40, height: 40)
                        .background(
                            Circle()
                                .fill(.blue.opacity(0.1))
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

struct TrendChartView: View {
    @EnvironmentObject var dataManager: ExpenseDataManager
    @State private var animatePie = false
    
    var pieData: [PieSliceData] {
        let currentMonth = Calendar.current.component(.month, from: Date())
        let currentYear = Calendar.current.component(.year, from: Date())
        let calendar = Calendar.current
        let startOfMonth = calendar.date(from: DateComponents(year: currentYear, month: currentMonth, day: 1))!
        let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth)!
        
        let monthlyExpenses = dataManager.expenses.filter { expense in
            expense.date >= startOfMonth && expense.date <= endOfMonth
        }
        
        let categoryGroups = Dictionary(grouping: monthlyExpenses) { $0.category }
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
            Text("支出分布")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.primary)
            
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
                HStack(spacing: 20) {
                    // Pie Chart
                    ZStack {
                        PieChart(data: pieData, animate: animatePie)
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
    }
}

// Data Models
struct MonthlyStats {
    let totalExpense: Double
    let dailyAverage: Double
    let recordCount: Int
    let averagePerRecord: Double
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