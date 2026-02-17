import SwiftUI

struct ModePickerView: View {
    @Binding var selectedMode: AnalysisMode

    var body: some View {
        HStack(spacing: 2) {
            ForEach(AnalysisMode.allCases) { mode in
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        selectedMode = mode
                    }
                } label: {
                    VStack(spacing: 2) {
                        Image(systemName: mode.icon)
                            .font(.system(size: 14))
                        Text(mode.title)
                            .font(.system(size: 10))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .background(selectedMode == mode ? Color.accentColor.opacity(0.15) : Color.clear)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)
                .foregroundStyle(selectedMode == mode ? .primary : .secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
    }
}
