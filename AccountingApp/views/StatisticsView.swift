// StatisticsView.swift
import SwiftUI

struct StatisticsView: View {
    @State private var animateCards = false
    @State private var animateChart = false
    
    let monthlyStats = MonthlyStats(
        totalExpense: 2847,
        dailyAverage: 94.9,
        recordCount: 68,
        averagePerRecord: 41.9
    )
    
    let categoryStats = [
        CategoryStat(name: "餐饮", icon: "fork.knife", amount: 1280, percentage: 45),
        CategoryStat(name: "娱乐", icon: "tv", amount: 712, percentage: 25),
        CategoryStat(name: "交通", icon: "car", amount: 427, percentage: 15),
        CategoryStat(name: "购物", icon: "bag", amount: 285, percentage: 10),
        CategoryStat(name: "其他", icon: "shippingbox", amount: 143, percentage: 5)
    ]
    
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
                    color: .primary,
                    animate: animate
                )
                .animation(.easeInOut.delay(0.1), value: animate)
                
                StatCard(
                    title: "日均支出",
                    value: String(format: "¥%.1f", stats.dailyAverage),
                    color: .secondary,
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
                    color: Color.green,
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
                        .foregroundColor(.primary)
                        .frame(width: 40, height: 40)
                        .background(
                            Circle()
                                .fill(.primary.opacity(0.1))
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
                        .foregroundColor(.primary)
                    
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
                            .thinMaterial
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
    @State private var animatePie = false
    
    let pieData = [
        PieSliceData(category: "餐饮", value: 1280, color: Color.blue),
        PieSliceData(category: "娱乐", value: 712, color: Color.green),
        PieSliceData(category: "交通", value: 427, color: Color.orange),
        PieSliceData(category: "购物", value: 285, color: Color.purple),
        PieSliceData(category: "其他", value: 143, color: Color.pink)
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("支出分布")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.primary)
            
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
                    ForEach(pieData, id: \.category) { slice in
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
