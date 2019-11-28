import Foundation
import SwiftUI

public struct ASNavigationDestination<Content: View> {
	var id: UUID? = UUID()
	var screenName: String?
	var content: Content
}
