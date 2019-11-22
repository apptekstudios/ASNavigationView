//
//  ASNavigationButton.swift
//  ASCollectionViewDemo
//
//  Created by Toby Brennan on 22/11/19.
//  Copyright © 2019 Apptek Studios. All rights reserved.
//

import Foundation
import SwiftUI


struct NeutralButtonStyle: ButtonStyle {
	
	func makeBody(configuration: Configuration) -> some View {
		configuration.label
	}
	
}

public struct ASNavigationButton<Label: View, Destination: View>: View {
	var destination: Destination
	var label: Label
	var screenName: String?
	
	@Environment(\.dynamicNavState) var dynamicNavState
	
	public init(screenName: String? = nil, destination: Destination, @ViewBuilder label: (() -> Label)) {
		self.screenName = screenName
		self.destination = destination
		self.label = label()
	}
	
	public init(screenName: String? = nil, @ViewBuilder destination: (() -> Destination), @ViewBuilder label: (() -> Label)) {
		self.screenName = screenName
		self.destination = destination()
		self.label = label()
	}
	
	public var body: some View {
		Button(action: {
			self.dynamicNavState.push(self.destination, withScreenName: self.screenName)
		}) {
			HStack {
				label
			}
		}
		.buttonStyle(NeutralButtonStyle())
	}
}


public struct ASNavigationDismissButton<Label: View>: View {
	var label: Label
	var dismissToScreenNamed: String?
	@Environment(\.dynamicNavState) var dynamicNavState
	
	public init(toScreenNamed screenName: String? = nil, @ViewBuilder label: (() -> Label)) {
		self.dismissToScreenNamed = screenName
		self.label = label()
	}
	
	public var body: some View {
		Button(action: {
			self.dynamicNavState.pop(toScreenNamed: self.dismissToScreenNamed)
		}) {
			label
		}
		.buttonStyle(PlainButtonStyle())
	}
}


public struct ASNavigationPopToRootButton<Label: View>: View {
	var label: Label
	@Environment(\.dynamicNavState) var dynamicNavState
	
	public init(@ViewBuilder label: (() -> Label)) {
		self.label = label()
	}
	
	public var body: some View {
		Button(action: {
			self.dynamicNavState.popToRoot()
		}) {
			label
		}
		.buttonStyle(PlainButtonStyle())
	}
}
