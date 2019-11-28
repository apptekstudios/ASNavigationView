import Foundation
import SwiftUI
import UIKit

struct ASNavigationController<Content: View, Placeholder: View>: UIViewControllerRepresentable {
	var content: Content
	var placeholderDetailView: Placeholder
	
	init(_ content: Content, placeholderDetailView: Placeholder) {
		self.content = content
		self.placeholderDetailView = placeholderDetailView
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
		context.coordinator.updateContentView()
		context.coordinator.updatePlaceholderView()
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
		var rootContentLayer: Layer?
		var placeholderContentLayer: Layer?
		
		var rootContentHost: ASHostingController<Content>? { rootContentLayer?.controller as? ASHostingController<Content> }
		var placeholderContentHost: ASHostingController<Placeholder>? { placeholderContentLayer?.controller as? ASHostingController<Placeholder> }
		
		init(_ parent: ASNavigationController) {
			self.parent = parent
			super.init()
			let root = createLayerForView(ASNavigationDestination(content: parent.content))
			self.controllerStack = [root]
			
			self.rootContentLayer = root
			self.placeholderContentLayer = createLayerForView(ASNavigationDestination(content: parent.placeholderDetailView))
		}
		
		func updateContentView() {
			self.rootContentHost?.setView(parent.content)
		}
		
		func updatePlaceholderView() {
			self.placeholderContentHost?.setView(parent.placeholderDetailView)
		}
		
		func createLayerForView<T: View>(_ destination: ASNavigationDestination<T>) -> Layer {
			let controller = ASHostingController<T>(destination.content)
			controller.parent = self
			controller.modifier = ASHostingControllerModifier(self, layerID: destination.id)
			return Layer(id: destination.id ?? UUID(), name: destination.screenName, controller: controller)
		}
		
		func push<T: View>(_ destination: ASNavigationDestination<T>, fromLayerID layerID: UUID) {
			let sourceLayerIndex = controllerStack.firstIndex(where: { $0.id == layerID }) ?? (controllerStack.endIndex - 1)
			var newStack = Array(controllerStack.prefix(through: sourceLayerIndex))
			var layer: Layer
			if let existingLayerIndex = controllerStack.lastIndex(where: { $0.id == destination.id }),
				existingLayerIndex > sourceLayerIndex //Check that the existing layer is downstream, otherwise we'll create a new one
			{
				layer = controllerStack[existingLayerIndex]
				if let layerHost = layer.controller as? ASHostingController<T> { //Check it is the right type
					layerHost.setView(destination.content) //Update content if needed
				} else {
					layer = createLayerForView(destination)
				}
			} else {
				layer = createLayerForView(destination)
			}
			//Append the layer to the stack
			newStack.append(layer)
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
			let placeholderVC = placeholderContentLayer?.controller.viewController
			nc.setViewControllers(vcs, detailPlaceholder: placeholderVC, animated: animated)
		}
		
		func willDismiss(_ host: ASHostingControllerProtocol) {
			controllerStack.removeAll { $0.controller === host }
		}
	}
}

protocol ASNavigationCoordinator: class {
	func push<T: View>(_ destination: ASNavigationDestination<T>, fromLayerID layerID: UUID)
	func pop(fromLayerID layerID: UUID, toScreenNamed screenName: String?)
	func popToRoot()
	func willDismiss(_ host: ASHostingControllerProtocol)
}

class ASNavigationController_UIKit: UISplitViewController {
	let masterNavController = ASNavigationSubController_UIKit()
	let detailNavController = ASNavigationSubController_UIKit()
	
	var stack: [UIViewController] = []
	var detailPlaceholder: UIViewController?
	var hasDetailContent: Bool {
		stack.count > 1
	}
	
	var stackWithPlaceholderIfRequired: [UIViewController] {
		if !hasDetailContent { return [stack.first, detailPlaceholder].compactMap { $0 }}
		return stack
	}
	var rootContent: UIViewController? { stackWithPlaceholderIfRequired.first }
	var detailContent: [UIViewController] { Array(stackWithPlaceholderIfRequired.dropFirst()) }
	
	init() {
		super.init(nibName: nil, bundle: nil)
		viewControllers = [masterNavController]
		self.delegate = self
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	func setViewControllers(_ vcs: [UIViewController], detailPlaceholder: UIViewController?, animated: Bool) {
		self.stack = vcs
		self.detailPlaceholder = detailPlaceholder
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
		
		if isCollapsed {
			masterNavController.setViewControllers(stack, animated: animated)
			detailNavController.viewControllers = [UIViewController()]
			viewControllers = [masterNavController, detailNavController]
		} else {
			masterNavController.setViewControllers([root], animated: animated)
			detailNavController.setViewControllers(detailContent, animated: animated)
			viewControllers = [masterNavController, detailNavController]
		}
		
		configureDisplayMode(hidePrimary: !detailContent.isEmpty)
	}
	
	func configureDisplayMode(hidePrimary: Bool = false) {
		let isIpadLandscape = UIDevice.current.userInterfaceIdiom == .pad && (view.window?.windowScene?.interfaceOrientation.isLandscape ?? false)
		
		if !hasDetailContent, !isCollapsed, !isIpadLandscape {
			preferredDisplayMode = .primaryOverlay
		} else {
			preferredDisplayMode = .automatic
		}
	
		if displayMode == .primaryOverlay && hidePrimary {
			preferredDisplayMode = .primaryHidden
		}
	}
	
	var lastBounds: CGRect = .zero
	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		//Opted to use didLayoutSubviews, as iPads will not change trait collection on moving to landscape
		if view.bounds != lastBounds {
			lastBounds = view.bounds
			configureDisplayMode()
		}
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
