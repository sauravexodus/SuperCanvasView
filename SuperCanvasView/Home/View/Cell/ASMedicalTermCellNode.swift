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

final class ASMedicalTermCellNode<ContentNode: CellContentNode>: ASCellNode where ContentNode.RepresentationTarget: MedicalTermType {
    internal let titleTextNode = ASTextNode().then {
        $0.maximumNumberOfLines = 0
    }
    
    internal let contentNode = ContentNode().then { _ in
        
    }
    
    let canvasNode = ASDisplayNode {
        CanvasView().then { $0.backgroundColor = .clear }
    }
    
    internal let editButtonNode = ASButtonNode().then {
        $0.setImage(UIImage(named: "Edit"), for: .normal)
    }
    
    internal let deleteButtonNode = ASButtonNode().then {
        $0.setImage(UIImage(named: "Delete"), for: .normal)
        $0.contentEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 16)
    }
    
    let textFont: UIFont = UIFont.preferredFont(forTextStyle: .body)
    
    var minimumHeight: CGFloat {
        let attributedText = NSAttributedString(string: "Random", attributes: [.font: textFont])
        let width = frame.size.width
        let height = attributedText.height(withConstrainedWidth: width)
        return height
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
        return titleTextNode.insets(.init(top: 0, left: 8, bottom: 0, right: 0)).relative(horizontalPosition: .start, verticalPosition: .start, sizingOption: [])
            .overlayed(by: contentNode)
            .overlayed(by: canvasNode)
            .overlayed(by: [editButtonNode, deleteButtonNode].stacked(in: .horizontal, spacing: 8, justifyContent: .end, alignItems: .start))
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
        style.preferredSize.height = min(CGFloat(max(CGFloat(item.height), item.lines.highestY ?? 0, minimumHeight)), maximumHeight)
        titleTextNode.attributedText = .init(string: term.name ?? "", attributes: [.foregroundColor: UIColor.darkGray, .font: textFont])

        contentNode.configure(with: term)
        self.item = item
    }
}

