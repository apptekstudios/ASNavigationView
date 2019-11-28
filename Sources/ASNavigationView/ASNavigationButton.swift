//
//  ASNavigationButton.swift
//  ASCollectionViewDemo
//
//  Created by Toby Brennan on 22/11/19.
//  Copyright © 2019 Apptek Studios. All rights reserved.
//

import Foundation
import SwiftUI

public struct ASNavigationButton<Label: View, ButtonStyleType: ButtonStyle, DestinationContent: View>: View {
	var style: ButtonStyleType
	var destination: ASNavigationDestination<DestinationContent>
	var label: Label
	
	@State private var defaultDestinationID = UUID() //Used if not passing a ASNavigationDestinatino
	
	@Environment(\.dynamicNavState) var dynamicNavState
	
	public init(style: ButtonStyleType, screenName: String? = nil, destination: DestinationContent, @ViewBuilder label: (() -> Label)) {
		self.style = style
		self.destination = ASNavigationDestination(id: nil, screenName: screenName, content: destination)
		self.label = label()
	}
	
	public init(style: ButtonStyleType, screenName: String? = nil, @ViewBuilder destination: (() -> DestinationContent), @ViewBuilder label: (() -> Label)) {
		self.init(style: style, screenName: screenName, destination: destination(), label: label)
	}
	
	public init(style: ButtonStyleType, destination: ASNavigationDestination<DestinationContent>, @ViewBuilder label: (() -> Label)) {
		self.style = style
		self.destination = destination
		self.label = label()
	}
	
	func pushContent() {
		var destination = self.destination
		destination.id = destination.id ?? defaultDestinationID // Use this button's default destinationID if we're not using ASNavigationDestination
		dynamicNavState.push(destination)
	}
	
	public var body: some View {
		return Button(action: {
			self.pushContent()
		}) {
			HStack {
				label
			}
		}
		.buttonStyle(style)
	}
}

extension ASNavigationButton where ButtonStyleType == ASButtonStyleNeutral {
	public init(screenName: String? = nil, destination: DestinationContent, @ViewBuilder label: (() -> Label)) {
		self.init(style: ASButtonStyleNeutral(), screenName: screenName, destination: destination, label: label)
	}
	
	public init(screenName: String? = nil, @ViewBuilder destination: (() -> DestinationContent), @ViewBuilder label: (() -> Label)) {
		self.init(style: ASButtonStyleNeutral(), screenName: screenName, destination: destination, label: label)
	}
	
	public init(destination: ASNavigationDestination<DestinationContent>, @ViewBuilder label: (() -> Label)) {
		self.init(style: ASButtonStyleNeutral(), destination: destination, label: label)
	}
}


public struct ASNavigationDismissButton<Label: View, ButtonStyleType: ButtonStyle>: View {
	var style: ButtonStyleType
	var label: Label
	var onDismiss: (()->())?
	var dismissToScreenNamed: String?
	@Environment(\.dynamicNavState) var dynamicNavState
	
	public init(style: ButtonStyleType, toScreenNamed screenName: String? = nil, onDismiss: (()->())? = nil, @ViewBuilder label: (() -> Label)) {
		self.style = style
		self.dismissToScreenNamed = screenName
		self.onDismiss = onDismiss
		self.label = label()
	}
	
	public var body: some View {
		Button(action: {
			self.onDismiss?()
			self.dynamicNavState.pop(toScreenNamed: self.dismissToScreenNamed)
		}) {
			label
		}
		.buttonStyle(style)
	}
}

extension ASNavigationDismissButton where ButtonStyleType == ASButtonStyleNeutral {
	public init(toScreenNamed screenName: String? = nil, onDismiss: (()->())? = nil, @ViewBuilder label: (() -> Label)) {
		self.init(style: ASButtonStyleNeutral(), toScreenNamed: screenName, onDismiss: onDismiss, label: label)
	}
}

public struct ASNavigationPopToRootButton<Label: View, ButtonStyleType: ButtonStyle>: View {
	var style: ButtonStyleType
	var label: Label
	var onPopToRoot: (()->())?
	@Environment(\.dynamicNavState) var dynamicNavState
	
	public init(style: ButtonStyleType, onPopToRoot: (()->())? = nil, @ViewBuilder label: (() -> Label)) {
		self.style = style
		self.onPopToRoot = onPopToRoot
		self.label = label()
	}
	
	public var body: some View {
		Button(action: {
			self.onPopToRoot?()
			self.dynamicNavState.popToRoot()
		}) {
			label
		}
		.buttonStyle(style)
	}
}

extension ASNavigationPopToRootButton where ButtonStyleType == ASButtonStyleNeutral {
	public init(onPopToRoot: (()->())? = nil, @ViewBuilder label: (() -> Label)) {
		self.init(style: ASButtonStyleNeutral(), onPopToRoot: onPopToRoot, label: label)
	}
}
