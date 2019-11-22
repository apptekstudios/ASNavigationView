import Foundation
import SwiftUI
import UIKit

struct ASNavigationController<Content: View>: UIViewControllerRepresentable {
	var content: Content
	
	
	init(_ content: Content) {
		self.content = content
	}
	
	func makeCoordinator() -> Coordinator {
		Coordinator(self)
	}
	
	func makeUIViewController(context: Context) -> ASNavigationController_UIKit {
		let navViewController = ASNavigationController_UIKit()
		context.coordinator.navController = navViewController
		return navViewController
	}
	
	func updateUIViewController(_ navController: ASNavigationController_UIKit, context: Context) {
		
	}
	
	class Coordinator: NSObject, ASNavigationCoordinator {
		var parent: ASNavigationController
		weak var navController: ASNavigationController_UIKit? {
			didSet {
				updateNavController(animated: false)
			}
		}
		
		struct Layer {
			var name: String? = nil
			var controller: ASHostingControllerProtocol
		}
		
		var controllerStack: [Layer] = []
		
		init(_ parent: ASNavigationController) {
			self.parent = parent
			super.init()
			self.controllerStack = [Layer(controller: hostForView(parent.content))]
		}
		
		func hostForView<T: View>(_ view: T) -> ASHostingControllerProtocol {
			let controller = ASHostingController<T>(view)
			controller.parent = self
			controller.modifier = ASHostingControllerModifier(self)
			return controller
		}
		
		func push<T: View>(_ view: T, withScreenName screenName: String? = nil) {
			self.controllerStack.append(
				Layer(name: screenName, controller: hostForView(view))
			)
			updateNavController(animated: true)
		}
		
		func pop(toScreenNamed screenName: String?) {
			guard self.controllerStack.count > 1 else { return }
			if let screenName = screenName, let screenIndex = controllerStack.lastIndex(where: { $0.name == screenName }) {
				controllerStack = Array(controllerStack.prefix(through: screenIndex))
			} else {
				controllerStack.removeLast()
			}
			updateNavController(animated: true)
		}
		
		func popToRoot() {
			controllerStack = controllerStack.first.map { [$0] } ?? []
			updateNavController(animated: true)
		}
		
		func updateNavController(animated: Bool) {
			guard let nc = navController else { return }
			let vcs = controllerStack.map { $0.controller.viewController }
			nc.setViewControllers(vcs, animated: animated)
		}
		
		func willDismiss(_ host: ASHostingControllerProtocol) {
			print(controllerStack)
			controllerStack.removeAll { $0.controller === host }
			print(controllerStack)
		}
	}
}

protocol ASNavigationCoordinator: class {
	func push<T: View>(_ view: T, withScreenName screenName: String?)
	func pop(toScreenNamed screenName: String?)
	func popToRoot()
	func updateNavController(animated: Bool)
	func willDismiss(_ host: ASHostingControllerProtocol)
}

class ASNavigationController_UIKit: UINavigationController {
	
	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		//printContent()
	}
	
	/*func printContent() {
		for controller in viewControllers.reversed() {
			let mirror = Mirror(reflecting: controller)
			
			for child in mirror.children {
				let mirror = Mirror(reflecting: child.value)
				print(mirror.subjectType)
			}
		}
	}*/
}
