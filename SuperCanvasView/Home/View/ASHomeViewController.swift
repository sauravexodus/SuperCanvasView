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
import ReactorKit
import RxSwift

final class ASHomeViewController: ASViewController<ASTableNode>, View {

    let tableNode = ASTableNode(style: .plain)
    let dataSource = Array(1...100).map { "Item \($0)" }
    
    var disposeBag: DisposeBag = DisposeBag()
    
    init(viewModel: HomeViewModel) {
        defer { self.reactor = viewModel }
        super.init(node: tableNode)
        tableNode.dataSource = self
        tableNode.delegate = self

        tableNode.view.panGestureRecognizer.allowedTouchTypes = [NSNumber(value: UITouchType.direct.rawValue)]
        tableNode.reloadData()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Bindings
    
    func bind(reactor: HomeViewModel) {
        bindActions(reactor: reactor)
        bindState(reactor: reactor)
    }
    
    private func bindActions(reactor: HomeViewModel) {
        
    }
    
    private func bindState(reactor: HomeViewModel) {
        
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
                view.configure(with: title, and: [])
                return view
            })
            cellNode.style.preferredSize = CGSize(width: CGFloat.greatestFiniteMagnitude, height: 160)
            return cellNode
        }
    }

}
