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
			var id: UUID
			var name: String? = nil
			var controller: ASHostingControllerProtocol
		}
		
		var controllerStack: [Layer] = []
		
		init(_ parent: ASNavigationController) {
			self.parent = parent
			super.init()
			self.controllerStack = [layerForView(parent.content, withScreenName: nil)]
		}
		
		func layerForView<T: View>(_ view: T, withScreenName screenName: String?) -> Layer {
			let id = UUID()
			let controller = ASHostingController<T>(view)
			controller.parent = self
			controller.modifier = ASHostingControllerModifier(self, layerID: id)
			return Layer(id: id, name: screenName, controller: controller)
		}
		
		func push<T: View>(_ view: T, fromLayerID layerID: UUID, withScreenName screenName: String? = nil) {
			let sourceLayerIndex = controllerStack.firstIndex(where: { $0.id == layerID }) ?? (controllerStack.endIndex - 1)
			var newStack = Array(controllerStack.prefix(through: sourceLayerIndex))
			newStack.append(
				layerForView(view, withScreenName: screenName)
			)
			controllerStack = newStack
			updateNavController(animated: true)
		}
		
		func pop(fromLayerID layerID: UUID, toScreenNamed screenName: String?) {
			guard self.controllerStack.count > 1 else { return }
			guard let sourceLayerIndex = controllerStack.firstIndex(where: { $0.id == layerID })  else { return }
			if let screenName = screenName, let screenIndex = controllerStack.prefix(upTo: sourceLayerIndex).lastIndex(where: { $0.name == screenName }) {
				controllerStack = Array(controllerStack.prefix(through: screenIndex))
			} else {
				controllerStack = Array(controllerStack.prefix(upTo: sourceLayerIndex))
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
			controllerStack.removeAll { $0.controller === host }
		}
	}
}

protocol ASNavigationCoordinator: class {
	func push<T: View>(_ view: T, fromLayerID layerID: UUID, withScreenName screenName: String?)
	func pop(fromLayerID layerID: UUID, toScreenNamed screenName: String?)
	func popToRoot()
	func willDismiss(_ host: ASHostingControllerProtocol)
}

class ASNavigationController_UIKit: UISplitViewController {
	let masterNavController = ASNavigationSubController_UIKit()
	let detailNavController = ASNavigationSubController_UIKit()
	
	var stack: [UIViewController] = []
	
	var rootContent: UIViewController? { stack.first }

	var detailContent: [UIViewController] { Array(stack.dropFirst()) }
	
	init() {
		super.init(nibName: nil, bundle: nil)
		viewControllers = [masterNavController]
		self.delegate = self
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		configureDisplayMode(forHorizontalSizeClass: traitCollection.horizontalSizeClass)
	}
	
	func setViewControllers(_ vcs: [UIViewController], animated: Bool) {
		self.stack = vcs
		configure(animated: animated)
	}
	
	func configure(animated: Bool) {
		guard let root = rootContent else {
			viewControllers = []
			return
		}
		let detailContent = self.detailContent
		detailContent.first?.navigationItem.leftBarButtonItem = displayModeButtonItem
		detailContent.first?.navigationItem.leftItemsSupplementBackButton = true
		
		if isCollapsed || detailContent.isEmpty {
			masterNavController.setViewControllers(stack, animated: animated)
			detailNavController.viewControllers = [UIViewController()]
			viewControllers = [masterNavController, detailNavController]
		} else {
			masterNavController.setViewControllers([root], animated: animated)
			detailNavController.setViewControllers(detailContent, animated: animated)
			viewControllers = [masterNavController, detailNavController]
		}
		
		configureDisplayMode(forHorizontalSizeClass: traitCollection.horizontalSizeClass, hidePrimary: !detailContent.isEmpty)
	}
	
	override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
		super.willTransition(to: newCollection, with: coordinator)
		configureDisplayMode(forHorizontalSizeClass: newCollection.horizontalSizeClass)
	}
	
	func configureDisplayMode(forHorizontalSizeClass horizontalSizeClass: UIUserInterfaceSizeClass, hidePrimary: Bool = false) {
		let isIpadLandscape = UIDevice.current.userInterfaceIdiom == .pad && (view.window?.windowScene?.interfaceOrientation.isLandscape ?? false)
		
		if detailContent.isEmpty, horizontalSizeClass == .regular, !isIpadLandscape {
			preferredDisplayMode = .primaryOverlay
		} else {
			preferredDisplayMode = .automatic
		}
	
		if displayMode == .primaryOverlay && hidePrimary {
			preferredDisplayMode = .primaryHidden
		}
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		configureDisplayMode(forHorizontalSizeClass: traitCollection.horizontalSizeClass)
	}
}

extension ASNavigationController_UIKit: UISplitViewControllerDelegate {
	func targetDisplayModeForAction(in svc: UISplitViewController) -> UISplitViewController.DisplayMode {
		if detailContent.isEmpty {
			return .allVisible
		}
		return .automatic
	}
	
	func primaryViewController(forExpanding splitViewController: UISplitViewController) -> UIViewController? {
		masterNavController
	}
	
	func primaryViewController(forCollapsing splitViewController: UISplitViewController) -> UIViewController? {
		masterNavController
	}
	
	func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController: UIViewController, onto primaryViewController: UIViewController) -> Bool {
		configure(animated: true)
		return true
	}
	
	func splitViewController(_ splitViewController: UISplitViewController, separateSecondaryFrom primaryViewController: UIViewController) -> UIViewController? {
		configure(animated: true)
		return detailNavController
	}
	
	override func collapseSecondaryViewController(_ secondaryViewController: UIViewController, for splitViewController: UISplitViewController) {
		// Do nothing
	}
}


class ASNavigationSubController_UIKit: UINavigationController {
}
