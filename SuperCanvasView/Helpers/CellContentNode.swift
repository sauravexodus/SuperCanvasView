//
//  CellContentNode.swift
//  SuperCanvasView
//
//  Created by Vatsal Manot on 10/10/18.
//  Copyright © 2018 Sourav Chandra. All rights reserved.
//

import AsyncDisplayKit
import Foundation

protocol _CellContentNode {
    associatedtype RepresentationTarget
    
    func configure(with _: RepresentationTarget)
}

typealias CellContentNode = _CellContentNode & ASDisplayNode

// MARK: Concrete Implementations

final class EmptyCellNode<T>: CellContentNode {
    typealias RepresentationTarget = T
    
    func configure(with _: T) {
        
    }
    
    override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        return ASLayoutSpec()
    }
}
