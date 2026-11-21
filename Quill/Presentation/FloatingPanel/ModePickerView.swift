import SwiftUI

/// Apple Look Up panel'in alt tab bar'ına yakın görsel:
/// kompakt, seçili sekme koyu pill bg ile vurgulu, ikon küçük + altta etiket.
struct ModePickerView: View {
    @Binding var selectedMode: AnalysisMode

    var body: some View {
        HStack(spacing: 4) {
            ForEach(AnalysisMode.allCases) { mode in
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        selectedMode = mode
                    }
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: mode.icon)
                            .font(.system(size: 11, weight: .medium))
                        Text(mode.title)
                            .font(.system(size: 11, weight: selectedMode == mode ? .semibold : .regular))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        selectedMode == mode
                            ? AnyShapeStyle(.quaternary)
                            : AnyShapeStyle(Color.clear)
                    )
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .foregroundStyle(selectedMode == mode ? .primary : .secondary)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity)
    }
}
