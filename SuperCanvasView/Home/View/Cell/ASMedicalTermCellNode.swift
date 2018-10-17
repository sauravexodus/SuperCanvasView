//
//  ASMedicalTermNodeCell.swift
//  SuperCanvasView
//
//  Created by Sourav Chandra on 07/10/18.
//  Copyright © 2018 Sourav Chandra. All rights reserved.
//

import Foundation
import AsyncDisplayKit
import SnapKit
import RxSwift

final class ASMedicalTermCellNode<ContentNode: CellContentNode>: ASCellNode, CanvasCompatibleCellNode where ContentNode.RepresentationTarget: MedicalTermType {
    internal let titleTextNode = ASTextNode().then {
        $0.maximumNumberOfLines = 0
    }
    
    internal let contentNode = ContentNode().then { _ in
        
    }
    
    var canvasNode = ASDisplayNode {
        CanvasView().then { $0.backgroundColor = .clear }
    }
    
    internal let editButtonNode = ASButtonNode().then {
        $0.setTitle("EDIT", with: UIFont.systemFont(ofSize: 12, weight: .semibold), with: .black, for: .normal)
        $0.contentEdgeInsets = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
    }
    
    internal let deleteButtonNode = ASButtonNode().then {
        $0.setTitle("DELETE", with: UIFont.systemFont(ofSize: 12, weight: .semibold), with: .black, for: .normal)
        $0.contentEdgeInsets = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
    }

    var header: String?
    let maximumHeight: CGFloat = 900
    let disposeBag = DisposeBag()
    var item: ConsultationRow?
    
    // MARK: Init methods
    
    override init() {
        super.init()
        selectionStyle = .none
        backgroundColor = .white
        automaticallyManagesSubnodes = true
    }
    
    // MARK: Lifecycle methods
    
    override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        return titleTextNode.insets(.all(16)).relative(horizontalPosition: .start, verticalPosition: .start, sizingOption: [])
            .overlayed(by: contentNode)
            .overlayed(by: canvasNode)
            .overlayed(by: [editButtonNode, deleteButtonNode].stacked(in: .horizontal, spacing: 16, justifyContent: .end, alignItems: .start).insets(UIEdgeInsets.all(16)))
    }
    
    override func animateLayoutTransition(_ context: ASContextTransitioning) {}
    
    override func didLoad() {
        setupUI()
        bind()
    }
    
    // MARK: Instance methods

    func configure(with item: ConsultationRow) {
        guard let term = item.medicalTerm as? ContentNode.RepresentationTarget else {
            print("Something has gone horribly, horribly awry...")
            return
        }
        style.preferredSize.height = min(CGFloat(max(CGFloat(item.height), item.lines.highestY ?? 0)), maximumHeight)
        titleTextNode.attributedText = .init(string: term.name ?? "", attributes: [.foregroundColor: UIColor.darkGray])

        contentNode.configure(with: term)
        self.item = item
    }
}

