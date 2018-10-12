//
//  ASAwareTableNode.swift
//  SuperCanvasView
//
//  Created by Sourav Chandra on 12/10/18.
//  Copyright © 2018 Sourav Chandra. All rights reserved.
//

import Foundation
import RxASDataSources
import AsyncDisplayKit
import RxSwift
import RxCocoa

typealias LinesWithIndexPath = (lines: [Line], indexPath: IndexPath)

final class ASAwareTableNode: ASTableNode {
    
    // MARK: Internal properties
    
    internal let endUpdateSubject = PublishSubject<Void>()
    internal let linesUpdateSubject = PublishSubject<LinesWithIndexPath>()
    
    // MARK: Public properties
    
    let disposeBag = DisposeBag()
    let animatedDataSource: RxASTableAnimatedDataSource<ConsultationSection>
    
    // MARK: Init methods
    
    override init(style: UITableViewStyle) {
        let configureCell: RxASTableAnimatedDataSource<ConsultationSection>.ConfigureCellBlock = { (ds, tableNode, index, item) in
            return {
                switch item.medicalTerm.sectionOfSelf {
                case .diagnoses:
                    let node = ASMedicalTermCellNode<EmptyCellNode<Diagnosis>>()
                    node.configure(with: item)
                    return node
                case .symptoms:
                    let node = ASMedicalTermCellNode<EmptyCellNode<Symptom>>()
                    node.configure(with: item)
                    return node
                default:
                    let node = ASMedicalTermCellNode<EmptyCellNode<NoMedicalTerm>>()
                    node.configure(with: item)
                    return node
                }
            }
        }
        
        animatedDataSource = RxASTableAnimatedDataSource(configureCellBlock: configureCell)
        
        super.init(style: style)
        delegate = self
    }
    
    // MARK: Instance methods
    
    internal func generateHeaderViewForSection(at index: Int) -> UIView {
        let text = animatedDataSource[index].medicalSection.displayTitle
        let font = UIFont.preferredPrintFont(forTextStyle: .footnote)
        let attributedText = NSAttributedString(string: text, attributes: [.font: font])
        let width = frame.size.width
        let height = attributedText.height(withConstrainedWidth: width)
        
        return UIView(frame: CGRect.zero).then {
            let label = UILabel(frame: CGRect(x: 0, y: 0, width: width, height: height)).then {
                $0.backgroundColor = .darkGray
                $0.textColor = .white
                $0.font = font
                $0.text = text
            }
            $0.addSubview(label)
        }
    }
    
}

// MARK: Delegates

extension ASAwareTableNode: ASTableDelegate {
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 16
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return generateHeaderViewForSection(at: section)
    }
    
    func tableNode(_ tableNode: ASTableNode, willDisplayRowWith node: ASCellNode) {
        if let medicalTermCellNode = node as? ASMedicalTermCellNode<EmptyCellNode<Diagnosis>> {
            medicalTermCellNode.linesChanged.debounce(0.3, scheduler: MainScheduler.instance)
                .bind(to: linesUpdateSubject)
                .disposed(by: medicalTermCellNode.disposeBag)
        } else if let medicalTermCellNode = node as? ASMedicalTermCellNode<EmptyCellNode<Symptom>> {
            medicalTermCellNode.linesChanged.debounce(0.3, scheduler: MainScheduler.instance)
                .bind(to: linesUpdateSubject)
                .disposed(by: medicalTermCellNode.disposeBag)
        } else if let medicalTermCellNode = node as? ASMedicalTermCellNode<EmptyCellNode<NoMedicalTerm>> {
            medicalTermCellNode.linesChanged.debounce(0.3, scheduler: MainScheduler.instance)
                .bind(to: linesUpdateSubject)
                .disposed(by: medicalTermCellNode.disposeBag)
        }
    }
    
    /// Since ASAwareTableNode's delegate is HomeViewController. We have to do this so that ASAwareTableNode is aware of the scrolling.
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        endUpdateSubject.onNext(())
    }
}
