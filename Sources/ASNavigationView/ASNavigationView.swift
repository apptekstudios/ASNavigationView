//
//  File.swift
//  
//
//  Created by Toby Brennan on 22/11/19.
//

import Foundation
import SwiftUI

public struct ASNavigationView<Content: View, Placeholder: View>: View {
	var controller: ASNavigationController<Content, Placeholder>
	
	
	public init(placeholderDetailView: Placeholder, @ViewBuilder content: (() -> Content)) {
		self.controller = ASNavigationController(content(), placeholderDetailView: placeholderDetailView)
	}
	
	public var body: some View {
		controller
			.edgesIgnoringSafeArea(.all)
	}
}

extension ASNavigationView where Placeholder == EmptyView {
	public init(@ViewBuilder _ content: (() -> Content)) {
		self.init(placeholderDetailView: EmptyView(), content: content)
	}
}
