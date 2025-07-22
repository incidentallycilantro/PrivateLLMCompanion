import SwiftUI

// MARK: - Filter Chip Component

struct FilterChip: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let count: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                
                Text(title)
                    .font(.caption)
                    .bold()
                
                if count > 0 {
                    Text("\(count)")
                        .font(.caption2)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(isSelected ? Color.white.opacity(0.3) : Color.secondary.opacity(0.3))
                        .cornerRadius(4)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(isSelected ? Color.blue : Color.gray.opacity(0.2))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.3), value: isSelected)
    }
}
