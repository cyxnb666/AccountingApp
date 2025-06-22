// CategoryManagementView.swift
import SwiftUI

struct CategoryManagementView: View {
    @EnvironmentObject var dataManager: ExpenseDataManager
    @Environment(\.dismiss) private var dismiss
    @State private var showingAddCategorySheet = false
    @State private var showingEditCategorySheet = false
    @State private var selectedCategory: ExpenseCategory?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                CategoryManagementHeaderView()
                
                // Categories List
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(dataManager.categories) { category in
                            CategoryManagementRow(
                                category: category,
                                onEdit: {
                                    selectedCategory = category
                                    showingEditCategorySheet = true
                                },
                                onDelete: {
                                    dataManager.deleteCategory(category)
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 100)
                }
                .background(Color(.systemGroupedBackground))
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingAddCategorySheet) {
            AddCategoryView()
                .environmentObject(dataManager)
        }
        .sheet(isPresented: $showingEditCategorySheet) {
            if let category = selectedCategory {
                EditCategoryView(category: category)
                    .environmentObject(dataManager)
            }
        }
    }
}

struct CategoryManagementHeaderView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showingAddCategorySheet = false
    
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
            
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(
                            Circle()
                                .fill(.white.opacity(0.2))
                        )
                }
                
                Spacer()
                
                VStack(spacing: 4) {
                    Text("分类管理")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("管理支出分类")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                }
                
                Spacer()
                
                Button(action: { showingAddCategorySheet = true }) {
                    Image(systemName: "plus")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(
                            Circle()
                                .fill(.white.opacity(0.2))
                        )
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 50)
            .padding(.bottom, 20)
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
        .sheet(isPresented: $showingAddCategorySheet) {
            AddCategoryView()
        }
    }
}

struct CategoryManagementRow: View {
    let category: ExpenseCategory
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // Category Icon and Name
            HStack(spacing: 12) {
                Image(systemName: category.icon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 50, height: 50)
                    .background(
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.3, green: 0.6, blue: 0.5),
                                        Color(red: 0.2, green: 0.5, blue: 0.4)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(category.name)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text("ID: \(category.id)")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Edit and Delete Buttons
            HStack(spacing: 12) {
                Button(action: onEdit) {
                    Image(systemName: "pencil")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.blue)
                        .frame(width: 36, height: 36)
                        .background(
                            Circle()
                                .fill(.blue.opacity(0.1))
                        )
                }
                
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.red)
                        .frame(width: 36, height: 36)
                        .background(
                            Circle()
                                .fill(.red.opacity(0.1))
                        )
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
    }
}

struct AddCategoryView: View {
    @EnvironmentObject var dataManager: ExpenseDataManager
    @Environment(\.dismiss) private var dismiss
    @State private var categoryName = ""
    @State private var selectedIcon = "questionmark"
    
    let availableIcons = [
        "fork.knife", "car", "tv", "bag", "cross", "gift", "lightbulb", "shippingbox",
        "house", "phone", "book", "gamecontroller", "music.note", "camera", "heart", "star"
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("添加新分类")
                    .font(.system(size: 24, weight: .bold))
                    .padding(.top, 20)
                
                // Name Input
                TextField("分类名称", text: $categoryName)
                    .font(.system(size: 18))
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray6))
                    )
                    .padding(.horizontal, 20)
                
                // Icon Selection
                Text("选择图标")
                    .font(.system(size: 18, weight: .semibold))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 16) {
                    ForEach(availableIcons, id: \.self) { icon in
                        Button(action: {
                            selectedIcon = icon
                        }) {
                            Image(systemName: icon)
                                .font(.system(size: 24, weight: .medium))
                                .foregroundColor(selectedIcon == icon ? .white : .primary)
                                .frame(width: 60, height: 60)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(selectedIcon == icon ? 
                                            LinearGradient(
                                                colors: [
                                                    Color(red: 0.3, green: 0.6, blue: 0.5),
                                                    Color(red: 0.2, green: 0.5, blue: 0.4)
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ) : 
                                            LinearGradient(
                                                colors: [Color(.systemGray6)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                )
                        }
                        .scaleEffect(selectedIcon == icon ? 1.1 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedIcon)
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer()
                
                // Add Button
                Button(action: addCategory) {
                    Text("添加分类")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.3, green: 0.6, blue: 0.5),
                                    Color(red: 0.2, green: 0.5, blue: 0.4)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal, 20)
                        .opacity(categoryName.isEmpty ? 0.6 : 1.0)
                }
                .disabled(categoryName.isEmpty)
                
                .padding(.bottom, 30)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func addCategory() {
        let newCategory = ExpenseCategory(
            id: UUID().uuidString,
            name: categoryName,
            icon: selectedIcon
        )
        dataManager.addCategory(newCategory)
        dismiss()
    }
}

struct EditCategoryView: View {
    @EnvironmentObject var dataManager: ExpenseDataManager
    @Environment(\.dismiss) private var dismiss
    @State private var categoryName: String
    @State private var selectedIcon: String
    
    let category: ExpenseCategory
    
    let availableIcons = [
        "fork.knife", "car", "tv", "bag", "cross", "gift", "lightbulb", "shippingbox",
        "house", "phone", "book", "gamecontroller", "music.note", "camera", "heart", "star"
    ]
    
    init(category: ExpenseCategory) {
        self.category = category
        self._categoryName = State(initialValue: category.name)
        self._selectedIcon = State(initialValue: category.icon)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("编辑分类")
                    .font(.system(size: 24, weight: .bold))
                    .padding(.top, 20)
                
                // Name Input
                TextField("分类名称", text: $categoryName)
                    .font(.system(size: 18))
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray6))
                    )
                    .padding(.horizontal, 20)
                
                // Icon Selection
                Text("选择图标")
                    .font(.system(size: 18, weight: .semibold))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 16) {
                    ForEach(availableIcons, id: \.self) { icon in
                        Button(action: {
                            selectedIcon = icon
                        }) {
                            Image(systemName: icon)
                                .font(.system(size: 24, weight: .medium))
                                .foregroundColor(selectedIcon == icon ? .white : .primary)
                                .frame(width: 60, height: 60)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(selectedIcon == icon ? 
                                            LinearGradient(
                                                colors: [
                                                    Color(red: 0.3, green: 0.6, blue: 0.5),
                                                    Color(red: 0.2, green: 0.5, blue: 0.4)
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ) : 
                                            LinearGradient(
                                                colors: [Color(.systemGray6)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                )
                        }
                        .scaleEffect(selectedIcon == icon ? 1.1 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedIcon)
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer()
                
                // Save Button
                Button(action: saveCategory) {
                    Text("保存更改")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.3, green: 0.6, blue: 0.5),
                                    Color(red: 0.2, green: 0.5, blue: 0.4)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal, 20)
                        .opacity(categoryName.isEmpty ? 0.6 : 1.0)
                }
                .disabled(categoryName.isEmpty)
                
                .padding(.bottom, 30)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func saveCategory() {
        let updatedCategory = ExpenseCategory(
            id: category.id,
            name: categoryName,
            icon: selectedIcon
        )
        dataManager.updateCategory(updatedCategory)
        dismiss()
    }
}