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
        CategoryStat(name: "餐饮", icon: "🍔", amount: 1280, percentage: 45),
        CategoryStat(name: "娱乐", icon: "🎬", amount: 712, percentage: 25),
        CategoryStat(name: "交通", icon: "🚗", amount: 427, percentage: 15),
        CategoryStat(name: "购物", icon: "🛍️", amount: 285, percentage: 10),
        CategoryStat(name: "其他", icon: "📦", amount: 143, percentage: 5)
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
                colors: [Color(hex: "667eea"), Color(hex: "764ba2")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            VStack(spacing: 8) {
                Text("支出统计")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text("了解您的消费习惯")
                    .font(.system(size: 16, weight: .medium))
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
                    color: Color(hex: "667eea"),
                    animate: animate
                )
                .animation(.easeInOut.delay(0.1), value: animate)
                
                StatCard(
                    title: "日均支出",
                    value: String(format: "¥%.1f", stats.dailyAverage),
                    color: Color(hex: "764ba2"),
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
                    Text(category.icon)
                        .font(.system(size: 24))
                        .frame(width: 40, height: 40)
                        .background(
                            Circle()
                                .fill(Color(hex: "667eea").opacity(0.1))
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
                        .foregroundColor(Color(hex: "667eea"))
                    
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
                                colors: [Color(hex: "667eea"), Color(hex: "764ba2")],
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
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("支出趋势")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.primary)
            
            // Placeholder for chart
            VStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 48))
                    .foregroundColor(Color(hex: "667eea").opacity(0.6))
                
                Text("图表功能开发中...")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 200)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemGray6))
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
