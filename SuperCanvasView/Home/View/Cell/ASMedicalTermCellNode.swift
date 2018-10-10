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

enum PageSize {
    case A4
    
    var size: CGSize {
        switch self {
        case .A4: return CGSize(width: width, height: height)
        }
    }
    
    var height: CGFloat {
        switch self {
        case .A4: return 842.0
        }
    }
    
    var width: CGFloat {
        switch self {
        case .A4: return 595.0
        }
    }
}

final class ASMedicalTermCellNode: ASCellNode {
    
    let titleTextNode = ASTextNode().then {
        $0.maximumNumberOfLines = 0
    }
    
    let canvasNode = ASDisplayNode {
        CanvasView().then { $0.backgroundColor = .clear }
    }

    let headerTextNode = ASTextNode().then {
        $0.maximumNumberOfLines = 0
        $0.backgroundColor = .darkGray
    }
    
    let editButtonNode = ASButtonNode().then {
        $0.setTitle("EDIT", with: UIFont.systemFont(ofSize: 12, weight: .semibold), with: .black, for: .normal)
        $0.contentEdgeInsets = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
    }
    
    let deleteButtonNode = ASButtonNode().then {
        $0.setTitle("DELETE", with: UIFont.systemFont(ofSize: 12, weight: .semibold), with: .black, for: .normal)
        $0.contentEdgeInsets = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
    }
    
    var height: CGFloat
    var headerText: String?
    let disposeBag = DisposeBag()
    
    // MARK: Init methods
    
    init(height: CGFloat, headerText: String? = nil) {
        self.height = height
        self.headerText = headerText
        super.init()
        backgroundColor = .white
        style.preferredSize.height = height
        automaticallyManagesSubnodes = true
        canvasNode.style.preferredSize.height = height
    }
    
    // MARK: Instance methods
    
    override func didLoad() {
        setupStyles()
        setupBindings()
        setupCanvasExpanding()
    }
    
    private func setupCanvasExpanding() {
        guard let canvasView = canvasNode.view as? CanvasView, let tableNode = owningNode as? ASAwareTableNode else { return }
        
        let tapObservable = Observable.merge(rx.tapGesture(configuration: { gesture, _ in
            gesture.allowedTouchTypes = [NSNumber(value: UITouchType.direct.rawValue)]
        })).mapTo(())
        
        Observable.merge(tapObservable, canvasView.rx.pencilTouchDidNearBottom)
            .subscribe(onNext: { [weak self] _ in
                guard let strongSelf = self else { return }
                UIView.setAnimationsEnabled(false)
                strongSelf.style.preferredSize.height = canvasView.highestY + 200
                strongSelf.transitionLayout(withAnimation: false, shouldMeasureAsync: false) {
                    canvasView.setNeedsDisplay()
                }
            })
            .disposed(by: disposeBag)
        
        Observable.merge(tapObservable, canvasView.rx.pencilDidStopMoving)
            .bind(to: tableNode.endUpdateSubject)
            .disposed(by: disposeBag)
        
        tableNode.endUpdateSubject.debounce(1, scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                guard let strongSelf = self else { return }
                UIView.setAnimationsEnabled(true)
                strongSelf.style.preferredSize.height = max(strongSelf.titleTextNode.frame.height, canvasView.highestY + 2, 50, strongSelf.editButtonNode.frame.height + 32)
                strongSelf.transitionLayout(withAnimation: false, shouldMeasureAsync: true) {
                    canvasView.setNeedsDisplay()
                }
            })
            .disposed(by: disposeBag)
    }
    
    private func setupBindings() {
        editButtonNode.rx.tap
            .subscribe(onNext: { _ in
                print("Edit Tapped")
            })
            .disposed(by: disposeBag)
        
        deleteButtonNode.rx.tap
            .subscribe(onNext: { _ in
                print("Delete Tapped")
            })
            .disposed(by: disposeBag)
    }
    
    private func setupStyles() {
        editButtonNode.layer.borderColor = UIColor.black.cgColor
        editButtonNode.layer.borderWidth = 2
        editButtonNode.layer.cornerRadius = 3
        
        deleteButtonNode.layer.borderColor = UIColor.black.cgColor
        deleteButtonNode.layer.borderWidth = 2
        deleteButtonNode.layer.cornerRadius = 3
    }

    func configure(with text: String?, and lines: [Line]) {
        titleTextNode.attributedText = NSAttributedString(string: text ?? "", attributes: [NSAttributedStringKey.foregroundColor: UIColor.darkGray])
    }
    
    // MARK: Lifecycle methods
    
    override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        return titleTextNode
            .insets(.all(16))
            .relative(
                horizontalPosition: .start,
                verticalPosition: .start,
                sizingOption: []
            )
            .overlayed(by: canvasNode)
            .overlayed(by: [editButtonNode, deleteButtonNode].stacked(in: .horizontal, spacing: 16, justifyContent: .end, alignItems: .start).insets(.all(16)))
    }
    
    override func animateLayoutTransition(_ context: ASContextTransitioning) {}
}
