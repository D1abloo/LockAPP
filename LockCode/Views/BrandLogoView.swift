import AppKit
import SwiftUI

struct BrandLogoView: View {
    let size: CGFloat

    var body: some View {
        Group {
            if let logo = Self.logoImage {
                Image(nsImage: logo)
                    .resizable()
                    .scaledToFit()
            } else {
                Image(systemName: "lock.fill")
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(.red)
                    .padding(size * 0.15)
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.2, style: .continuous))
        .accessibilityLabel("Candado cerrado de LockCode")
    }

    private static let logoImage: NSImage? = {
        guard let url = Bundle.main.url(forResource: "LockCodeLogo", withExtension: "png") else {
            return nil
        }
        return NSImage(contentsOf: url)
    }()
}
