// AccountingApp.swift
import SwiftUI

@main
struct AccountingApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.light) // 可以根据需要调整
        }
    }
}

// 如果需要数据持久化，可以添加这个数据管理器
class ExpenseDataManager: ObservableObject {
    @Published var expenses: [Expense] = []
    
    private let userDefaults = UserDefaults.standard
    private let expensesKey = "SavedExpenses"
    
    init() {
        loadExpenses()
    }
    
    func addExpense(_ expense: Expense) {
        expenses.append(expense)
        saveExpenses()
    }
    
    func deleteExpense(at index: Int) {
        expenses.remove(at: index)
        saveExpenses()
    }
    
    private func saveExpenses() {
        if let encoded = try? JSONEncoder().encode(expenses) {
            userDefaults.set(encoded, forKey: expensesKey)
        }
    }
    
    private func loadExpenses() {
        if let data = userDefaults.data(forKey: expensesKey),
           let decoded = try? JSONDecoder().decode([Expense].self, from: data) {
            expenses = decoded
        }
    }
}

// 支出数据模型
struct Expense: Identifiable, Codable {
    let id = UUID()
    let amount: Double
    let description: String
    let category: String
    let date: Date
    
    var categoryIcon: String {
        switch category {
        case "food": return "🍔"
        case "transport": return "🚗"
        case "entertainment": return "🎬"
        case "shopping": return "🛍️"
        case "medical": return "🏥"
        case "gift": return "🎁"
        case "bills": return "💡"
        default: return "📦"
        }
    }
    
    var categoryName: String {
        switch category {
        case "food": return "餐饮"
        case "transport": return "交通"
        case "entertainment": return "娱乐"
        case "shopping": return "购物"
        case "medical": return "医疗"
        case "gift": return "人情"
        case "bills": return "缴费"
        default: return "其他"
        }
    }
}

// 扩展Date以便于格式化
extension Date {
    func formatted(style: DateFormatter.Style) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = style
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: self)
    }
    
    func timeFormatted() -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: self)
    }
    
    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }
    
    var monthYear: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年MM月"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: self)
    }
}

// 数字格式化扩展
extension Double {
    var currencyFormatted: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "¥"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: NSNumber(value: self)) ?? "¥0"
    }
}

// 如果使用数据管理器，需要在ContentView中注入
struct ContentViewWithDataManager: View {
    @StateObject private var dataManager = ExpenseDataManager()
    @State private var selectedTab = 0
    
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
            
            TabView(selection: $selectedTab) {
                AddExpenseViewWithDataManager()
                    .environmentObject(dataManager)
                    .tag(0)
                
                MonthlyRecordsView()
                    .environmentObject(dataManager)
                    .tag(1)
                
                StatisticsView()
                    .environmentObject(dataManager)
                    .tag(2)
                
                SettingsView()
                    .tag(3)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            
            VStack {
                Spacer()
                CustomTabBar(selectedTab: $selectedTab)
            }
        }
        .onAppear {
            UITabBar.appearance().isHidden = true
        }
    }
}

// 扩展版本的AddExpenseView，集成数据管理功能
struct AddExpenseViewWithDataManager: View {
    @EnvironmentObject var dataManager: ExpenseDataManager
    @State private var amount = ""
    @State private var description = ""
    @State private var selectedCategory = "food"
    @State private var showingSuccessAlert = false
    
    let categories = [
        ("food", "🍔", "餐饮"),
        ("transport", "🚗", "交通"),
        ("entertainment", "🎬", "娱乐"),
        ("shopping", "🛍️", "购物"),
        ("medical", "🏥", "医疗"),
        ("gift", "🎁", "人情"),
        ("bills", "💡", "缴费"),
        ("other", "📦", "其他")
    ]
    
    var todayExpenses: [(String, String)] {
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        
        return dataManager.expenses
            .filter { $0.date >= today && $0.date < tomorrow }
            .map { ($0.description, String(format: "%.0f", $0.amount)) }
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
        .alert("记账成功", isPresented: $showingSuccessAlert) {
            Button("确定", role: .cancel) { }
        } message: {
            Text("已记录：¥\(amount) - \(description)")
        }
    }
    
    private func addExpense() {
        guard let amountValue = Double(amount), !description.isEmpty else {
            return
        }
        
        let expense = Expense(
            amount: amountValue,
            description: description,
            category: selectedCategory,
            date: Date()
        )
        
        dataManager.addExpense(expense)
        showingSuccessAlert = true
        
        // Reset form
        amount = ""
        description = ""
    }
}
