// AddExpenseView.swift
import SwiftUI

struct AddExpenseView: View {
    @State private var amount = ""
    @State private var description = ""
    @State private var selectedCategory = "food"
    @State private var showingSuccessAlert = false
    
    let categories = [
        ("food", "fork.knife", "餐饮"),
        ("transport", "car", "交通"),
        ("entertainment", "tv", "娱乐"),
        ("shopping", "bag", "购物"),
        ("medical", "cross", "医疗"),
        ("gift", "gift", "人情"),
        ("bills", "lightbulb", "缴费"),
        ("other", "shippingbox", "其他")
    ]
    
    let todayExpenses = [
        ("午饭", "14"),
        ("地铁", "6"),
        ("奶茶看电影", "35")
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header
                HeaderView()
                
                // Quick Add Section
                QuickAddSection(
                    amount: $amount,
                    description: $description,
                    selectedCategory: $selectedCategory,
                    categories: categories,
                    onAddExpense: {
                        addExpense()
                    }
                )
                
                // Today's Records
                TodayRecordsSection(expenses: todayExpenses)
                
                // Bottom padding for tab bar
                Spacer(minLength: 100)
            }
        }
        .background(Color(.systemGroupedBackground))
        .onTapGesture {
            hideKeyboard()
        }
        .alert("记账成功", isPresented: $showingSuccessAlert) {
            Button("确定", role: .cancel) { }
        } message: {
            Text("已记录：¥\(amount) - \(description)")
        }
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    private func addExpense() {
        guard !amount.isEmpty && !description.isEmpty else {
            return
        }
        showingSuccessAlert = true
        // Reset form
        amount = ""
        description = ""
    }
}

struct HeaderView: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.2, green: 0.4, blue: 0.8),
                    Color(red: 0.1, green: 0.3, blue: 0.7)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            VStack(spacing: 8) {
                Text("记账助手")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text("2025年6月15日 星期日")
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

struct QuickAddSection: View {
    @Binding var amount: String
    @Binding var description: String
    @Binding var selectedCategory: String
    let categories: [(String, String, String)]
    let onAddExpense: () -> Void
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Amount Input
            VStack(spacing: 15) {
                HStack {
                    Text("¥")
                        .font(.system(size: 48, weight: .ultraLight))
                        .foregroundColor(.primary)
                    
                    TextField("0.00", text: $amount)
                        .font(.system(size: 48, weight: .ultraLight))
                        .foregroundColor(.primary)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.leading)
                }
                
                Rectangle()
                    .fill(.primary.opacity(0.3))
                    .frame(height: 2)
                    .animation(.easeInOut, value: amount.isEmpty)
            }
            
            // Description Input
            TextField("添加描述，如：午饭、地铁...", text: $description)
                .font(.system(size: 16))
                .padding(15)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                )
            
            // Category Grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 15) {
                ForEach(categories, id: \.0) { category in
                    CategoryItem(
                        icon: category.1,
                        title: category.2,
                        isSelected: selectedCategory == category.0
                    ) {
                        withAnimation(.spring()) {
                            selectedCategory = category.0
                        }
                    }
                }
            }
            
            // Add Button
            Button(action: {
                hideKeyboard()
                onAddExpense()
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 20, weight: .semibold))
                    Text("记一笔")
                        .font(.system(size: 18, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [
                            Color(red: 0.2, green: 0.6, blue: 0.9),
                            Color(red: 0.1, green: 0.5, blue: 0.8)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: Color(red: 0.1, green: 0.5, blue: 0.8).opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .scaleEffect(amount.isEmpty || description.isEmpty ? 0.95 : 1.0)
            .animation(.spring(), value: amount.isEmpty || description.isEmpty)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.05), radius: 15, x: 0, y: 8)
        )
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }
}

struct CategoryItem: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    var body: some View {
        Button(action: {
            hideKeyboard()
            action()
        }) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(isSelected ? .white : .primary)
                    .scaleEffect(isSelected ? 1.2 : 1.0)
                
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(isSelected ? .white : .primary)
            }
            .frame(height: 70)
            .frame(maxWidth: .infinity)
            .background(
                Group {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.2, green: 0.6, blue: 0.9),
                                        Color(red: 0.1, green: 0.5, blue: 0.8)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    } else {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray6))
                    }
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isSelected ? Color.white.opacity(0.3) : Color.clear,
                        lineWidth: 2
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

struct TodayRecordsSection: View {
    let expenses: [(String, String)]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("今日支出")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("¥\(totalAmount)")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
            }
            
            VStack(spacing: 12) {
                ForEach(Array(expenses.enumerated()), id: \.offset) { index, expense in
                    HStack {
                        Circle()
                            .fill(.primary.opacity(0.2))
                            .frame(width: 8, height: 8)
                        
                        Text(expense.0)
                            .font(.system(size: 16))
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Text("¥\(expense.1)")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.ultraThinMaterial)
                    )
                    .animation(.easeInOut.delay(Double(index) * 0.1), value: expenses.count)
                }
            }
        }
        .padding(20)
    }
    
    private var totalAmount: String {
        let total = expenses.compactMap { Double($0.1) }.reduce(0, +)
        return String(format: "%.0f", total)
    }
}
