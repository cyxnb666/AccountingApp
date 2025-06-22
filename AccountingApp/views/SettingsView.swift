// SettingsView.swift
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var dataManager: ExpenseDataManager
    @State private var monthlyBudget = 5000.0
    @State private var reminderTime = Date()
    @State private var isReminderEnabled = true
    @State private var showingBudgetAlert = false
    @State private var showingExportAlert = false
    @State private var showingClearDataAlert = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header
                SettingsHeaderView()
                
                VStack(spacing: 20) {
                    // Budget Settings
                    BudgetSettingsSection(
                        monthlyBudget: $monthlyBudget,
                        showingAlert: $showingBudgetAlert
                    )
                    
                    // Notification Settings
                    NotificationSettingsSection(
                        isEnabled: $isReminderEnabled,
                        reminderTime: $reminderTime
                    )
                    
                    // Category Management
                    CategoryManagementSection()
                    
                    // Data Management
                    DataManagementSection(
                        showingExportAlert: $showingExportAlert,
                        showingClearDataAlert: $showingClearDataAlert,
                        onClearData: {
                            dataManager.clearAllData()
                        }
                    )
                }
                .padding(.top, 20)
                .padding(.bottom, 100) // Space for tab bar
            }
        }
        .background(Color(.systemGroupedBackground))
        .alert("设置预算", isPresented: $showingBudgetAlert) {
            TextField("输入预算金额", value: $monthlyBudget, format: .number)
                .keyboardType(.numberPad)
            Button("确定") { }
            Button("取消", role: .cancel) { }
        } message: {
            Text("设置您的月度预算目标")
        }
        .alert("导出成功", isPresented: $showingExportAlert) {
            Button("确定", role: .cancel) { }
        } message: {
            Text("数据已导出到相册")
        }
        .alert("清空数据", isPresented: $showingClearDataAlert) {
            Button("确认清空", role: .destructive) {
                dataManager.clearAllData()
            }
            Button("取消", role: .cancel) { }
        } message: {
            Text("此操作将清空所有记账数据，且不可恢复")
        }
    }
}

struct SettingsHeaderView: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.3, green: 0.6, blue: 0.5),
                    Color(red: 0.2, green: 0.5, blue: 0.4)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            VStack(spacing: 8) {
                Text("设置")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text("个性化您的记账体验")
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

struct BudgetSettingsSection: View {
    @Binding var monthlyBudget: Double
    @Binding var showingAlert: Bool
    
    var body: some View {
        SettingsSection(title: "预算设置") {
            SettingsRow(
                icon: "dollarsign.circle.fill",
                iconColor: .green,
                title: "月度预算",
                value: "¥\(Int(monthlyBudget))"
            ) {
                showingAlert = true
            }
            
            SettingsRow(
                icon: "chart.pie.fill",
                iconColor: .orange,
                title: "预算提醒",
                value: monthlyBudget > 4000 ? "已开启" : "已关闭",
                showChevron: false
            ) { }
        }
    }
}

struct NotificationSettingsSection: View {
    @Binding var isEnabled: Bool
    @Binding var reminderTime: Date
    
    var body: some View {
        SettingsSection(title: "提醒设置") {
            HStack {
                HStack(spacing: 12) {
                    Image(systemName: "bell.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                        .frame(width: 28, height: 28)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.blue)
                        )
                    
                    Text("记账提醒")
                        .font(.system(size: 16))
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                Toggle("", isOn: $isEnabled)
                    .tint(.primary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            
            if isEnabled {
                Divider()
                    .padding(.horizontal, 16)
                
                HStack {
                    HStack(spacing: 12) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.primary)
                            .frame(width: 28, height: 28)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.purple)
                            )
                        
                        Text("提醒时间")
                            .font(.system(size: 16))
                            .foregroundColor(.primary)
                    }
                    
                    Spacer()
                    
                    DatePicker("", selection: $reminderTime, displayedComponents: .hourAndMinute)
                        .labelsHidden()
                        .accentColor(.primary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .transition(.opacity.combined(with: .offset(y: -10)))
            }
        }
    }
}

struct CategoryManagementSection: View {
    @EnvironmentObject var dataManager: ExpenseDataManager
    @State private var showingCategoryManagement = false
    
    var body: some View {
        SettingsSection(title: "分类管理") {
            SettingsRow(
                icon: "folder.fill",
                iconColor: .primary,
                title: "支出分类",
                value: "\(dataManager.categories.count)个分类"
            ) {
                showingCategoryManagement = true
            }
        }
        .sheet(isPresented: $showingCategoryManagement) {
            CategoryManagementView()
                .environmentObject(dataManager)
        }
    }
}

struct DataManagementSection: View {
    @Binding var showingExportAlert: Bool
    @Binding var showingClearDataAlert: Bool
    let onClearData: () -> Void
    
    var body: some View {
        SettingsSection(title: "数据管理") {
            SettingsRow(
                icon: "square.and.arrow.up.fill",
                iconColor: .blue,
                title: "导出数据",
                value: "Excel格式",
                showChevron: false
            ) {
                showingExportAlert = true
            }
            
            SettingsRow(
                icon: "trash.fill",
                iconColor: .red,
                title: "清空数据",
                value: "谨慎操作"
            ) {
                showingClearDataAlert = true
            }
        }
    }
}


struct SettingsSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)
                .padding(.horizontal, 20)
            
            VStack(spacing: 0) {
                content
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
            )
            .padding(.horizontal, 20)
        }
    }
}

struct SettingsRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String
    var showChevron: Bool = true
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                HStack(spacing: 12) {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                        .frame(width: 28, height: 28)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(iconColor)
                        )
                    
                    Text(title)
                        .font(.system(size: 16))
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                if !value.isEmpty {
                    Text(value)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                
                if showChevron {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}
