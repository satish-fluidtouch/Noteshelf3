import SwiftUI

public struct ValueSliderStyleConfiguration {
    public let value: Binding<CGFloat>
    public let bounds: ClosedRange<CGFloat>
    public let step: CGFloat
    public var tapped: Binding<Bool>
    public let onEditingChanged: (Bool) -> Void
    public var dragOffset: Binding<CGFloat?>
    
    public init(value: Binding<CGFloat>, bounds: ClosedRange<CGFloat>, step: CGFloat, tapped: Binding<Bool>, onEditingChanged: @escaping (Bool) -> Void, dragOffset: Binding<CGFloat?>) {
        self.value = value
        self.bounds = bounds
        self.step = step
        self.tapped = tapped
        self.onEditingChanged = onEditingChanged
        self.dragOffset = dragOffset
    }
    
    func with(dragOffset: Binding<CGFloat?>) -> Self {
        var mutSelf = self
        mutSelf.dragOffset = dragOffset
        return mutSelf
    }
}
