//
//  ASMedicalTermCellNode+UI.swift
//  SuperCanvasView
//
//  Created by Sourav Chandra on 12/10/18.
//  Copyright © 2018 Sourav Chandra. All rights reserved.
//

import Foundation
import AsyncDisplayKit


// MARK: Animations

extension ASMedicalTermCellNode {
    func expand() {
        guard let canvasView = canvasNode.view as? CanvasView else { return }
        guard style.preferredSize.height < maximumHeight else { return }
        style.preferredSize.height = min(max((canvasView.highestY) + 200, style.preferredSize.height), maximumHeight)
        transitionLayout(withAnimation: false, shouldMeasureAsync: false) {
            canvasView.setNeedsDisplay()
        }
    }
    
    func contract(interactionType: ASAwareTableNode.InteractionType) {
        guard let canvasView = canvasNode.view as? CanvasView else { return }
        guard let `item` = item else { return }
        let newHeight = min(max((canvasView.highestY) + 4, item.height), maximumHeight)
        style.preferredSize.height = newHeight
        transitionLayout(withAnimation: false, shouldMeasureAsync: true) {
            guard case .scribble = interactionType else { return }
            canvasView.setNeedsDisplay()
        }
    }
}

// MARK: Styling

extension ASMedicalTermCellNode {
    
    internal func setupUI() {
        setupCanvas()
        setupStyles()
    }
    
    private func setupCanvas() {
        guard let `item` = item, let canvasView = canvasNode.view as? CanvasView else { return }
        canvasView.lines = item.lines
        canvasView.setNeedsDisplay()
    }
    
    private func setupStyles() {
        editButtonNode.layer.borderColor = UIColor.black.cgColor
        editButtonNode.layer.borderWidth = 2
        editButtonNode.layer.cornerRadius = 3
        
        deleteButtonNode.layer.borderColor = UIColor.black.cgColor
        deleteButtonNode.layer.borderWidth = 2
        deleteButtonNode.layer.cornerRadius = 3
    }
}
