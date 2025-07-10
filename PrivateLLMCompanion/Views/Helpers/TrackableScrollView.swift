import SwiftUI

struct TrackableScrollView<Content: View>: View {
    let onScroll: (Bool) -> Void
    let content: (Bool) -> Content

    @State private var isAtBottom: Bool = true

    var body: some View {
        GeometryReader { outsideProxy in
            ScrollView {
                VStack(spacing: 0) {
                    content(isAtBottom)
                        .background(
                            GeometryReader { geo in
                                Color.clear
                                    .preference(key: ScrollOffsetKey.self, value: geo.frame(in: .global).maxY)
                            }
                        )
                }
            }
            .onPreferenceChange(ScrollOffsetKey.self) { value in
                let viewHeight = outsideProxy.frame(in: .global).maxY
                let offsetToBottom = abs(viewHeight - value)
                let isNowAtBottom = offsetToBottom < 100
                if isAtBottom != isNowAtBottom {
                    isAtBottom = isNowAtBottom
                    onScroll(isAtBottom)
                }
            }
        }
    }
}

private struct ScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
