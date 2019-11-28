import Foundation
import SwiftUI

public struct ASNavigationDestination<Content: View> {
	var id: UUID?
	var screenName: String?
	var content: Content
	
	internal init(id: UUID?, screenName: String? = nil, content: Content) {
		self.id = id
		self.screenName = screenName
		self.content = content
	}
}
