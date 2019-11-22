//
//  File.swift
//  
//
//  Created by Toby Brennan on 22/11/19.
//

import Foundation
import SwiftUI

public struct ASNavigationView<Content: View>: View {
	var controller: ASNavigationController<Content>
	
	
	public init(@ViewBuilder _ content: (() -> Content)) {
		self.controller = ASNavigationController(content())
	}
	
	public var body: some View {
		controller
			.edgesIgnoringSafeArea(.all)
	}
}
