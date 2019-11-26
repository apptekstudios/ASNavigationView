//
//  ASNavigationState.swift
//  ASCollectionViewDemo
//
//  Created by Toby Brennan on 22/11/19.
//  Copyright © 2019 Apptek Studios. All rights reserved.
//

import Foundation
import SwiftUI

struct ASNavigationState {
	weak var coordinator: ASNavigationCoordinator?
	var layerID: UUID?
	
	func push<T: View>(_ view: T, withScreenName screenName: String? = nil) {
		guard let layerID = layerID else { print("Tried to use ASNavigationLink that is not within an ASNavigationView"); return }
		coordinator?.push(view, fromLayerID: layerID, withScreenName: screenName)
	}
	func pop(toScreenNamed screenName: String? = nil) {
		guard let layerID = layerID else { print("Tried to use ASNavigationLink that is not within an ASNavigationView"); return  }
		coordinator?.pop(fromLayerID: layerID, toScreenNamed: screenName)
	}
	func popToRoot() {
		coordinator?.popToRoot()
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
