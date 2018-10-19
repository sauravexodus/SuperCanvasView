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
    
    let textFont: UIFont = UIFont.preferredPrintFont(forTextStyle: .body)
    
    var minimumHeight: CGFloat {
        let attributedText = NSAttributedString(string: "Random", attributes: [.font: textFont])
        let width = frame.size.width
        let height = attributedText.height(withConstrainedWidth: width)
        return height + bottomInset
    }
    
    let bottomInset: CGFloat = 4
    let leftInset: CGFloat = 12
    
    var header: String?
    let maximumHeight: CGFloat = PageSize.selectedPage.height
    let terminalCellHeight: CGFloat = 40
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
        a4CanvasStack.children = [ canvasNode.then { $0.style.preferredSize.width = PageSize.selectedPage.width }, ASLayoutSpec().then { $0.style.flexGrow = 1 } ]
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
        // TODO: Improve
        guard let form = item.medicalForm as? ContentNode.RepresentationTarget else {
            style.preferredSize.height = terminalCellHeight
            titleTextNode.attributedText = .init(string: "", attributes: [.foregroundColor: UIColor.darkGray, .font: textFont])
            self.item = item
            return
        }
        style.preferredSize.height = min(CGFloat(max(CGFloat(item.height), item.lines.highestY ?? 0, minimumHeight)), maximumHeight)
        titleTextNode.attributedText = form.value ?? NSAttributedString(string: "", attributes: [.foregroundColor: UIColor.darkGray, .font: textFont])
        contentNode.configure(with: form)
        self.item = item
    }
}

