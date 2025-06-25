// AddExpenseView.swift
import SwiftUI

struct AddExpenseView: View {
    @EnvironmentObject var dataManager: ExpenseDataManager
    @State private var amount = ""
    @State private var description = ""
    @State private var selectedCategory = ""
    @State private var isButtonPressed = false
    @State private var showingSuccessAnimation = false
    @State private var showSuccessMessage = false
    
    var categories: [(String, String, String)] {
        dataManager.categories.map { ($0.id, $0.icon, $0.name) }
    }
    
    var todayExpenses: [Expense] {
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        
        return dataManager.expenses
            .filter { $0.date >= today && $0.date < tomorrow }
    }
    
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
                    isButtonPressed: $isButtonPressed,
                    showingSuccessAnimation: $showingSuccessAnimation,
                    onAddExpense: {
                        addExpense()
                    }
                )
                
                // Today's Records
                TodayRecordsSection(expenses: todayExpenses, dataManager: dataManager)
                
                // Bottom padding for tab bar
                Spacer(minLength: 100)
            }
        }
        .background(Color(.systemGroupedBackground))
        .onTapGesture {
            hideKeyboard()
        }
        .onAppear {
            if selectedCategory.isEmpty && !categories.isEmpty {
                selectedCategory = categories.first?.0 ?? ""
            }
        }
        .overlay(
            VStack {
                if showSuccessMessage {
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.green)
                        
                        Text("记账成功")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.primary)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 25)
                            .fill(.ultraThinMaterial)
                            .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                    )
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .scale).combined(with: .offset(y: -20)),
                        removal: .opacity.combined(with: .offset(y: -30))
                    ))
                }
                Spacer()
            }
            .padding(.top, 120)
        )
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    private func addExpense() {
        guard let amountValue = Double(amount), !description.isEmpty else {
            return
        }
        
        // 添加触觉反馈
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        let expense = Expense(
            id: UUID(),
            amount: amountValue,
            description: description,
            category: selectedCategory,
            date: Date()
        )
        
        dataManager.addExpense(expense)
        
        // 先显示成功动画，然后显示页内提示
        withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
            showingSuccessAnimation = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            showingSuccessAnimation = false
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                showSuccessMessage = true
            }
        }
        
        // 2秒后隐藏成功提示
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.3) {
            withAnimation(.easeOut(duration: 0.4)) {
                showSuccessMessage = false
            }
        }
        
        // Reset form with animation
        withAnimation(.easeOut(duration: 0.3)) {
            amount = ""
            description = ""
        }
    }
    
    private func formatCurrentTime() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: Date())
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
    @Binding var isButtonPressed: Bool
    @Binding var showingSuccessAnimation: Bool
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
            
            // Add Button with enhanced animations
            Button(action: {
                hideKeyboard()
                // 添加按钮按下效果
                withAnimation(.easeInOut(duration: 0.1)) {
                    isButtonPressed = true
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isButtonPressed = false
                    }
                    onAddExpense()
                }
            }) {
                HStack(spacing: 12) {
                    if showingSuccessAnimation {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20, weight: .semibold))
                            .transition(.scale.combined(with: .opacity))
                    } else {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 20, weight: .semibold))
                            .transition(.scale.combined(with: .opacity))
                    }
                    
                    Text(showingSuccessAnimation ? "记账成功" : "记一笔")
                        .font(.system(size: 18, weight: .semibold))
                        .transition(.opacity)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    Group {
                        if showingSuccessAnimation {
                            LinearGradient(
                                colors: [
                                    Color.green.opacity(0.8),
                                    Color.green.opacity(0.6)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        } else {
                            LinearGradient(
                                colors: [
                                    Color(red: 0.2, green: 0.6, blue: 0.9),
                                    Color(red: 0.1, green: 0.5, blue: 0.8)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        }
                    }
                )
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .shadow(
                    color: showingSuccessAnimation ? 
                        Color.green.opacity(0.4) : 
                        Color(red: 0.1, green: 0.5, blue: 0.8).opacity(0.3),
                    radius: isButtonPressed ? 4 : 10,
                    x: 0,
                    y: isButtonPressed ? 2 : 6
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(
                            showingSuccessAnimation ? 
                                Color.green.opacity(0.6) : 
                                Color.white.opacity(0.3),
                            lineWidth: 1
                        )
                )
            }
            .scaleEffect(
                amount.isEmpty || description.isEmpty ? 0.95 : 
                (isButtonPressed ? 0.97 : (showingSuccessAnimation ? 1.05 : 1.0))
            )
            .disabled(amount.isEmpty || description.isEmpty)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: amount.isEmpty)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: description.isEmpty)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isButtonPressed)
            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: showingSuccessAnimation)
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
    let expenses: [Expense]
    let dataManager: ExpenseDataManager
    
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
            
            if expenses.isEmpty {
                VStack {
                    Image(systemName: "tray")
                        .font(.system(size: 48))
                        .foregroundColor(.gray.opacity(0.6))
                    
                    Text("今日还没有支出记录")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                VStack(spacing: 12) {
                    ForEach(expenses) { expense in
                        ExpenseRowView(expense: expense, dataManager: dataManager)
                    }
                }
            }
        }
        .padding(20)
    }
    
    private var totalAmount: String {
        let total = expenses.map { $0.amount }.reduce(0, +)
        return String(format: "%.0f", total)
    }
}

struct ExpenseRowView: View {
    let expense: Expense
    let dataManager: ExpenseDataManager
    @State private var showingDeleteAlert = false
    
    var body: some View {
        HStack {
            HStack(spacing: 12) {
                Image(systemName: expense.categoryIcon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.blue)
                    .frame(width: 20)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(expense.description)
                        .font(.system(size: 16))
                        .foregroundColor(.primary)
                    
                    Text(expense.categoryName)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text("¥\(String(format: "%.0f", expense.amount))")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
            }
            
            Button(action: {
                showingDeleteAlert = true
            }) {
                Image(systemName: "trash")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.red)
                    .frame(width: 32, height: 32)
                    .background(
                        Circle()
                            .fill(Color.red.opacity(0.1))
                    )
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
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