import SwiftUI
import UIKit

/// The app's look: white cards on a pearl-grey page, a black ink button, soft grey wells
/// for text fields. Every colour has a light and a dark version.
enum Pearl {
    static let page = Color(light: 0xECEDF1, dark: 0x0B0B0D)
    static let card = Color(light: 0xFFFFFF, dark: 0x1C1C1E)
    static let well = Color(light: 0xF4F4F7, dark: 0x2C2C2E)
    static let track = Color(light: 0xE8E8ED, dark: 0x2C2C2E)
    static let pill = Color(light: 0xFFFFFF, dark: 0x4A4A4E)
    static let ink = Color(light: 0x111114, dark: 0xF5F5F7)
    static let onInk = Color(light: 0xFFFFFF, dark: 0x111114)
    static let rim = Color(light: 0xFFFFFF, dark: 0xFFFFFF, lightAlpha: 0.9, darkAlpha: 0.07)

    static let cardRadius: CGFloat = 28
    static let wellRadius: CGFloat = 16
}

extension Color {
    /// A colour that switches with light and dark mode. Hex values are 0xRRGGBB.
    init(light: UInt32, dark: UInt32, lightAlpha: CGFloat = 1, darkAlpha: CGFloat = 1) {
        self.init(uiColor: UIColor { traits in
            let isDark = traits.userInterfaceStyle == .dark
            let hex = isDark ? dark : light
            return UIColor(
                red: CGFloat((hex >> 16) & 0xFF) / 255,
                green: CGFloat((hex >> 8) & 0xFF) / 255,
                blue: CGFloat(hex & 0xFF) / 255,
                alpha: isDark ? darkAlpha : lightAlpha
            )
        })
    }
}

// MARK: - Card

private struct PearlCardModifier: ViewModifier {
    let radius: CGFloat

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        // The shadow sits on the background shape only, so text and fields inside
        // the card don't get shadows of their own.
        content
            .background {
                shape
                    .fill(Pearl.card)
                    .shadow(color: .black.opacity(0.04), radius: 1, y: 1)
                    .shadow(color: .black.opacity(0.06), radius: 14, y: 8)
            }
            .overlay(shape.strokeBorder(Pearl.rim, lineWidth: 1))
    }
}

extension View {
    /// A white rounded card with a soft shadow.
    func pearlCard(radius: CGFloat = Pearl.cardRadius) -> some View {
        modifier(PearlCardModifier(radius: radius))
    }

    /// A soft grey rounded well around a text field, with an optional leading symbol.
    func pearlWell(icon: String? = nil) -> some View {
        HStack(spacing: 12) {
            if let icon {
                Image(systemName: icon)
                    .foregroundStyle(.tertiary)
                    .frame(width: 20)
            }
            self
        }
        .padding(.horizontal, 16)
        .frame(minHeight: 52)
        .background(Pearl.well, in: RoundedRectangle(cornerRadius: Pearl.wellRadius, style: .continuous))
    }
}

// MARK: - Ink button

/// The black capsule button used for every main action.
struct InkButtonStyle: ButtonStyle {
    var fullWidth = true

    func makeBody(configuration: Configuration) -> some View {
        InkLabel(configuration: configuration, fullWidth: fullWidth)
    }

    private struct InkLabel: View {
        let configuration: ButtonStyleConfiguration
        let fullWidth: Bool
        @Environment(\.isEnabled) private var isEnabled

        var body: some View {
            configuration.label
                .font(.body.weight(.semibold))
                .foregroundStyle(Pearl.onInk)
                .padding(.horizontal, fullWidth ? 0 : 26)
                .frame(maxWidth: fullWidth ? .infinity : nil, minHeight: 54)
                .background(Pearl.ink, in: Capsule())
                .opacity(isEnabled ? (configuration.isPressed ? 0.85 : 1) : 0.35)
                .scaleEffect(configuration.isPressed ? 0.97 : 1)
                .animation(.snappy(duration: 0.2), value: configuration.isPressed)
        }
    }
}

// MARK: - Segmented switch

/// A grey track with a raised white pill that slides to the selected option.
struct PearlSegmented<Value: Hashable>: View {
    @Binding var selection: Value
    let options: [(value: Value, label: String)]
    @Namespace private var namespace

    var body: some View {
        HStack(spacing: 0) {
            ForEach(options, id: \.value) { option in
                let isSelected = option.value == selection
                Button {
                    withAnimation(.snappy(duration: 0.25)) { selection = option.value }
                } label: {
                    Text(option.label)
                        .font(.subheadline.weight(isSelected ? .semibold : .medium))
                        .foregroundStyle(isSelected ? .primary : .secondary)
                        .frame(maxWidth: .infinity, minHeight: 34)
                        .background {
                            if isSelected {
                                RoundedRectangle(cornerRadius: 11, style: .continuous)
                                    .fill(Pearl.pill)
                                    .shadow(color: .black.opacity(0.12), radius: 2, y: 1)
                                    .matchedGeometryEffect(id: "pill", in: namespace)
                            }
                        }
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
        .padding(3)
        .background(Pearl.track, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

// MARK: - Small pieces

/// The blue app badge with a checkmark, used on the sign-in screen.
struct AppBadge: View {
    var size: CGFloat = 76

    var body: some View {
        RoundedRectangle(cornerRadius: size * 0.25, style: .continuous)
            .fill(LinearGradient(colors: [Color(red: 0.16, green: 0.55, blue: 1), Color(red: 0, green: 0.42, blue: 0.93)],
                                 startPoint: .top, endPoint: .bottom))
            .frame(width: size, height: size)
            .overlay {
                Image(systemName: "checkmark")
                    .font(.system(size: size * 0.42, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .shadow(color: Color(red: 0, green: 0.42, blue: 0.93).opacity(0.28), radius: 14, y: 8)
            .accessibilityHidden(true)
    }
}

/// A small grey label above a field ("Title", "Description").
struct FieldLabel: View {
    let text: String

    init(_ text: String) { self.text = text }

    var body: some View {
        Text(text)
            .font(.footnote.weight(.medium))
            .foregroundStyle(.secondary)
            .padding(.leading, 4)
            .padding(.bottom, 6)
    }
}
