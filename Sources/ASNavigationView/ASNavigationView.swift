import SwiftUI


public struct ASNavigationView<Content: View>: View {
	var content: Content
	
	public init(@ViewBuilder _ content: (() -> Content)) {
		self.content = content()
	}
	
	public var body: some View {
		NavigationView {
			ASNavigationLayer {
				content
			}
		}
	}
}

public struct ASNavigationLayer<Content: View>: View {
	var content: Content
	@State var currentContent: AnyView?
	
	var hasContent: Binding<Bool> {
		Binding(get: { self.currentContent != nil }, set: { if !$0 { self.currentContent = nil } })
	}
	
	public init(@ViewBuilder _ content: (() -> Content)) {
		self.content = content()
	}
	
	func modifyEnvironment<T: View>(_ view: T) -> some View {
		view.transformEnvironment(\.dynamicNavState) { state in
			state.addScreen(
				ASNavigationState.Screen(push: { self.currentContent = $0 },
									   pop: { self.currentContent = nil })
			)
		}
	}
	
	public var body: some View {
		VStack {
			modifyEnvironment(content)
			NavigationLink(destination: modifyEnvironment(currentContent), isActive: hasContent) { EmptyView() }
		}
	}
}

public struct ASNavigationButton<Label: View, Destination: View>: View {
	var destination: Destination
	var label: Label
	@Environment(\.dynamicNavState) var dynamicNavState
	
	public init(destination: Destination, @ViewBuilder label: (() -> Label)) {
		self.destination = destination
		self.label = label()
	}
	
	public init(@ViewBuilder destination: (() -> Destination), @ViewBuilder label: (() -> Label)) {
		self.destination = destination()
		self.label = label()
	}
	
	public var body: some View {
		Button(action: {
			self.dynamicNavState.push(self.destination)
		}) {
			label
		}
		.buttonStyle(NeutralButtonStyle())
	}
}

struct NeutralButtonStyle: ButtonStyle {
	
	func makeBody(configuration: Configuration) -> some View {
		configuration.label
	}
	
}

public struct ASNavigationDismissButton<Label: View>: View {
	var label: Label
	@Environment(\.dynamicNavState) var dynamicNavState
	
	public init(@ViewBuilder label: (() -> Label)) {
		self.label = label()
	}
	
	public var body: some View {
		Button(action: {
			self.dynamicNavState.pop()
		}) {
			label
		}
		.buttonStyle(PlainButtonStyle())
	}
}

struct ASNavigationState {
	var screens: [Screen] = []
	struct Screen {
		var push: ((AnyView) -> ())
		var pop: (() -> ())
	}
	
	//Used to construct the environment
	mutating func addScreen(_ screen: Screen) {
		screens.append(screen)
	}
	
	//Used to present a view
	func push<Content: View>(_ view: Content) {
		let erasedView = AnyView(view)
		guard let screen = screens.last else {
			return
		}
		screen.push(erasedView)
	}
	
	//Used to pop to the parent view
	func pop() {
		guard let screen = screens.last else {
			return
		}
		screen.pop()
	}
}

struct EnvironmentKeyASNavigationState: EnvironmentKey
{
	static let defaultValue: ASNavigationState = ASNavigationState()
}

extension EnvironmentValues
{
	var dynamicNavState: ASNavigationState
	{
		get { return self[EnvironmentKeyASNavigationState.self] }
		set { self[EnvironmentKeyASNavigationState.self] = newValue }
	}
}

