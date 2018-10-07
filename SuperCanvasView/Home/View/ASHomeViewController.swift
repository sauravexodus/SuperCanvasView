//
//  ASHomeViewController.swift
//  SuperCanvasView
//
//  Created by Sourav Chandra on 07/10/18.
//  Copyright © 2018 Sourav Chandra. All rights reserved.
//

import Foundation
import UIKit
import AsyncDisplayKit

final class ASHomeViewController: ASViewController<ASTableNode> {
    
    let tableNode = ASTableNode(style: .plain)
    let dataSource = Array(1...100).map { "Item \($0)" }
    
    init() {
        super.init(node: tableNode)
        tableNode.dataSource = self
        tableNode.delegate = self

        tableNode.view.panGestureRecognizer.allowedTouchTypes = [NSNumber(value: UITouchType.direct.rawValue)]
        tableNode.reloadData()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

extension ASHomeViewController: ASTableDataSource, ASTableDelegate {
    func tableNode(_ tableNode: ASTableNode, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }

    func tableNode(_ tableNode: ASTableNode, nodeBlockForRowAt indexPath: IndexPath) -> ASCellNodeBlock {
        let title = dataSource[indexPath.row]
        return { () -> ASCellNode in
            let cellNode = ASCellNode(viewBlock: { () -> UIView in
                let view = ASMedicalTermCellNode()
                view.backgroundColor = .white
                view.configure(with: title, and: [], height: 160)
                return view
            })
            cellNode.style.preferredSize = CGSize(width: CGFloat.greatestFiniteMagnitude, height: 160)
            return cellNode
        }
    }

}
