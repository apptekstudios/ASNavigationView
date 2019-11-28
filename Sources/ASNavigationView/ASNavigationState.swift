//
//  ASNavigationState.swift
//  ASCollectionViewDemo
//
//  Created by Toby Brennan on 22/11/19.
//  Copyright © 2019 Apptek Studios. All rights reserved.
//

import Foundation
import SwiftUI

public struct ASNavigationState {
	internal weak var coordinator: ASNavigationCoordinator?
	internal var layerID: UUID?
	
	public func push<T: View>(_ destination: ASNavigationDestination<T>) {
		guard let layerID = layerID else { print("Tried to use ASNavigationLink that is not within an ASNavigationView"); return }
		coordinator?.push(destination, fromLayerID: layerID)
	}
	public func pop(toScreenNamed screenName: String? = nil) {
		guard let layerID = layerID else { print("Tried to use ASNavigationLink that is not within an ASNavigationView"); return  }
		coordinator?.pop(fromLayerID: layerID, toScreenNamed: screenName)
	}
	public func popToRoot() {
		coordinator?.popToRoot()
	}
}

struct EnvironmentKeyASNavigationState: EnvironmentKey
{
	static let defaultValue: ASNavigationState = ASNavigationState()
}

extension EnvironmentValues
{
	public var navigationState: ASNavigationState
	{
		get { return self[EnvironmentKeyASNavigationState.self] }
		set { self[EnvironmentKeyASNavigationState.self] = newValue }
	}
}
