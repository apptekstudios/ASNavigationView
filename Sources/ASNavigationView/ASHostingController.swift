// ASCollectionView. Created by Apptek Studios 2019

import Foundation
import SwiftUI

internal struct ASHostingControllerModifier: ViewModifier
{
	weak var coordinator: ASNavigationCoordinator?
	var layerID: UUID?
	
	init(_ coordinator: ASNavigationCoordinator? = nil, layerID: UUID?) {
		self.coordinator = coordinator
		self.layerID = layerID
	}
	
	func body(content: Content) -> some View
	{
		content
			.transformEnvironment(\.dynamicNavState) { state in
				state.layerID = self.layerID
				state.coordinator = self.coordinator
		}
	}
}

internal protocol ASHostingControllerProtocol: class
{
	var viewController: UIViewController { get }
	func applyModifier(_ modifier: ASHostingControllerModifier)
	func willDismiss()
}

internal class ASHostingController<ViewType: View>: ASHostingControllerProtocol
{
	init(_ view: ViewType)
	{
		self.hostedView = view
		self.uiHostingController = .init(rootView: view.modifier(ASHostingControllerModifier(layerID: nil)))
		self.uiHostingController.owner = self
	}
	
	weak var parent: ASNavigationCoordinator?
	
	let uiHostingController: ASUIHostingController<ModifiedContent<ViewType, ASHostingControllerModifier>>
	var viewController: UIViewController
	{
		uiHostingController.view.backgroundColor = .systemBackground
		uiHostingController.view.insetsLayoutMarginsFromSafeArea = false
		return uiHostingController as UIViewController
	}
	
	var hostedView: ViewType
	var modifier: ASHostingControllerModifier = ASHostingControllerModifier(layerID: nil)
	{
		didSet
		{
			uiHostingController.rootView = hostedView.modifier(modifier)
		}
	}
	
	func setView(_ view: ViewType)
	{
		hostedView = view
		uiHostingController.rootView = hostedView.modifier(modifier)
	}
	
	func applyModifier(_ modifier: ASHostingControllerModifier)
	{
		self.modifier = modifier
	}
	
	func willDismiss() {
		parent?.willDismiss(self)
	}
}


internal class ASUIHostingController<Content: View> : UIHostingController<Content> {
	weak var owner: ASHostingControllerProtocol?
	override func willMove(toParent parent: UIViewController?) {
		if parent == nil {
			owner?.willDismiss()
		}
	}
}
