//
//  ASPageBreakNodeCell.swift
//  SuperCanvasView
//
//  Created by Sourav Chandra on 13/10/18.
//  Copyright © 2018 Sourav Chandra. All rights reserved.
//

import Foundation
import AsyncDisplayKit

final class ASPageBreakCellNode: ASCellNode {
    internal let titleTextNode = ASTextNode().then {
        $0.maximumNumberOfLines = 0
    }
    override init() {
        super.init()
        backgroundColor = .red
        style.preferredSize.height = 30
        automaticallyManagesSubnodes = true
    }
    
    override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        let insets = UIEdgeInsets(top: 0, left: 12, bottom: 4, right: 4)
        let inset = ASInsetLayoutSpec(insets: insets, child: titleTextNode)
        return ASCenterLayoutSpec(centeringOptions: .Y, sizingOptions: .minimumX, child: inset)
    }
    
    func configure(with item: ConsultationRow) {
        guard case let .pageBreak(pageNumber, pageHeight) = item else {
            fatalError("This is a not page break row type!")
        }
        titleTextNode.attributedText = .init(string: "Page: \(pageNumber) after height: \(pageHeight)", attributes: [.foregroundColor: UIColor.white, .font: UIFont.preferredPrintFont(forTextStyle: .body)])
    }
}
