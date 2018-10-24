//
//  ASMedicalFormCellNode.swift
//  SuperCanvasView
//
//  Created by Krishna C Aluru on 10/19/18.
//  Copyright © 2018 Sourav Chandra. All rights reserved.
//

import Foundation
import AsyncDisplayKit
import SnapKit
import RxSwift

final class ASMedicalFormCellNode<ContentNode: CellContentNode>: ASCellNode, CanvasCompatibleCellNode where ContentNode.RepresentationTarget: MedicalFormType {
    internal let titleTextNode = ASTextNode().then {
        $0.maximumNumberOfLines = 0
    }
    
    internal let contentNode = ContentNode().then { _ in
        
    }
    
    var canvasNode = ASDisplayNode {
        CanvasView().then { $0.backgroundColor = UIColor.lightGray.withAlphaComponent(0.3) }
    }
    
    let bottomInset: CGFloat = 4
    let leftInset: CGFloat = 12
    var header: String?
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
        let a4CanvasStack: ASStackLayoutSpec = .horizontal()
        a4CanvasStack.children = [ canvasNode.then { $0.style.preferredSize.width = PageSize.selectedPage.widthRemovingMargins }, ASLayoutSpec().then { $0.style.flexGrow = 1 } ]
        return titleTextNode.insets(.init(top: 0, left: leftInset, bottom: bottomInset, right: 0)).relative(horizontalPosition: .start, verticalPosition: .start, sizingOption: [])
            .overlayed(by: contentNode)
            .overlayed(by: a4CanvasStack)
    }
    
    override func animateLayoutTransition(_ context: ASContextTransitioning) {}
    
    override func didLoad() {
        setupUI()
        bind()
    }
    
    // MARK: Instance methods
    
    func configure(with item: ConsultationRow) {
        self.item = item
        style.preferredSize.height = item.height
        guard let form = item.medicalForm as? ContentNode.RepresentationTarget else {
            titleTextNode.attributedText = .init(string: "", attributes: [.foregroundColor: UIColor.darkGray, .font: FontSpecification.medicalFormText])
            return
        }
        titleTextNode.attributedText = form.value ?? NSAttributedString(string: "", attributes: [.foregroundColor: UIColor.darkGray, .font: FontSpecification.medicalFormText])
        contentNode.configure(with: form)
    }
}

