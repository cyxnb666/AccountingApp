// MonthlyRecordsView.swift
import SwiftUI

struct MonthlyRecordsView: View {
    @State private var currentMonth = 6
    @State private var currentYear = 2025
    @State private var selectedDate = Date()
    
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
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            MonthlyHeaderView()
            
            // Month Selector
            MonthSelectorView(
                currentMonth: $currentMonth,
                currentYear: $currentYear
            )
            
            // Records List
            ScrollView {
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
            .background(Color(.systemGroupedBackground))
        }
    }
}

struct MonthlyHeaderView: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "667eea"), Color(hex: "764ba2")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            VStack(spacing: 8) {
                Text("月度记录")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text("查看每月支出明细")
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

struct MonthSelectorView: View {
    @Binding var currentMonth: Int
    @Binding var currentYear: Int
    
    var body: some View {
        HStack {
            Button(action: previousMonth) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color(hex: "667eea"))
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
                    .foregroundColor(Color(hex: "667eea"))
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
                            .foregroundColor(Color(hex: "667eea"))
                        
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
                                .fill(Color(hex: "667eea").opacity(0.2))
                                .frame(width: 6, height: 6)
                            
                            Text(expense.description)
                                .font(.system(size: 14))
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Text("¥\(expense.amount)")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color(hex: "667eea"))
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
                .stroke(Color(hex: "667eea").opacity(isExpanded ? 0.3 : 0.1), lineWidth: 1)
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
