import Foundation
import SwiftUI

public struct ASButtonStyleNeutral: ButtonStyle {
	public init() { }
	public func makeBody(configuration: Configuration) -> some View {
		configuration.label
	}
}

public struct ASButtonStyleList: ButtonStyle {
	public init() { }
	public func makeBody(configuration: Configuration) -> some View {
		VStack(spacing: 0) {
			Spacer()
			HStack(spacing: 0) {
				configuration.label
				Spacer()
				Image(systemName: "chevron.right")
					.foregroundColor(Color(.tertiaryLabel))
					.font(.system(size: 14, weight: .semibold))
					.offset(x: configuration.isPressed ? 3 : 0)
					.animation(.default)
			}
			Spacer()
		}
		.padding(.horizontal)
		.background(Color(configuration.isPressed ? .secondarySystemBackground : .systemBackground))
		.contentShape(Rectangle())
		.listRowInsets(EdgeInsets())
	}
	
}

struct NeutralButtonStyle_Previews: PreviewProvider
{
	static var previews: some View
	{
		Button(action: {
			//Nothing
		}) {
			Text("Test label")
		}
		.buttonStyle(ASButtonStyleNeutral())
		.previewLayout(.fixed(width: 200, height: 50))
	}
}
