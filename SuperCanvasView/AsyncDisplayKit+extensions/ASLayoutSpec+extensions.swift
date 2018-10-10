//
//  ASLayoutSpec+extensions.swift
//  SuperCanvasView
//
//  Created by Sourav Chandra on 10/10/18.
//  Copyright © 2018 Sourav Chandra. All rights reserved.
//

import Foundation
import AsyncDisplayKit

extension ASLayoutSpec {
    func insets(_ insets: UIEdgeInsets) -> ASInsetLayoutSpec {
        return ASInsetLayoutSpec(insets: insets, child: self)
    }
    
    func overlayed(by spec: ASLayoutSpec) -> ASOverlayLayoutSpec {
        return ASOverlayLayoutSpec(child: self, overlay: spec)
    }
    
    func overlayed(by node: ASDisplayNode) -> ASOverlayLayoutSpec {
        return ASOverlayLayoutSpec(child: self, overlay: node)
    }
    
    func overlayed(on spec: ASLayoutSpec) -> ASOverlayLayoutSpec {
        return ASOverlayLayoutSpec(child: spec, overlay: self)
    }
    
    func overlayed(on node: ASDisplayNode) -> ASOverlayLayoutSpec {
        return ASOverlayLayoutSpec(child: node, overlay: self)
    }
    
    func relative(horizontalPosition: ASRelativeLayoutSpecPosition, verticalPosition: ASRelativeLayoutSpecPosition, sizingOption: ASRelativeLayoutSpecSizingOption) -> ASRelativeLayoutSpec {
        return ASRelativeLayoutSpec(horizontalPosition: horizontalPosition, verticalPosition: verticalPosition, sizingOption: sizingOption, child: self)
    }
}

extension Array where Element: ASLayoutSpec {
    func stacked(in direction: ASStackLayoutDirection, spacing: CGFloat, justifyContent: ASStackLayoutJustifyContent, alignItems: ASStackLayoutAlignItems) -> ASStackLayoutSpec {
        return ASStackLayoutSpec(direction: direction, spacing: spacing, justifyContent: justifyContent, alignItems: alignItems, children: self)
    }
}
