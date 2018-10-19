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

protocol CanvasCompatibleCellNode {
    var canvasNode: ASDisplayNode { get }
    func expand()
}

final class ASAwareTableNode: ASTableNode {
    
    static var canvasTool: CanvasTool = .pencil
    
    enum InteractionType {
        case scroll
        case scribble
        case tap
    }
    
    // MARK: Internal properties

    internal let linesUpdateSubject = PublishSubject<LinesWithIndexPath>()
    internal let itemDeleted = PublishSubject<IndexPath>()
    
    // MARK: Public properties
    
    let disposeBag = DisposeBag()
    let animatedDataSource: RxASTableAnimatedDataSource<ConsultationSection>
    
    // MARK: Canvas controls
    
    var undoableActionsIndexes: [IndexPath] = []
    var redoableActionsIndexes: [IndexPath] = []
    
    // MARK: Init methods
    
    override init(style: UITableViewStyle) {
        let configureCell: RxASTableAnimatedDataSource<ConsultationSection>.ConfigureCellBlock = { (ds, tableNode, index, item) in
            return {
                switch item {
                case .medicalTerm:
                    guard let termSection = item.medicalTermSection else { fatalError("Medical term without a section!") }
                    switch termSection {
                    case .symptoms:
                        let node = ASMedicalTermCellNode<TerminalCellNode<Symptom>>()
                        node.configure(with: item)
                        return node
                    case .diagnoses:
                        let node = ASMedicalTermCellNode<TerminalCellNode<Diagnosis>>()
                        node.configure(with: item)
                        return node
                    case .examinations:
                        let node = ASMedicalTermCellNode<TerminalCellNode<Examination>>()
                        node.configure(with: item)
                        return node
                    case .prescriptions:
                        let node = ASMedicalTermCellNode<TerminalCellNode<Prescription>>()
                        node.configure(with: item)
                        return node
                    case .tests:
                        let node = ASMedicalTermCellNode<TerminalCellNode<Test>>()
                        node.configure(with: item)
                        return node
                    case .procedures:
                        let node = ASMedicalTermCellNode<TerminalCellNode<Procedure>>()
                        node.configure(with: item)
                        return node
                    case .instructions:
                        let node = ASMedicalTermCellNode<TerminalCellNode<Instruction>>()
                        node.configure(with: item)
                        return node
                    }
                case .medicalForm:
                    guard let formSection = item.medicalFormSection else { fatalError("Medical form without a section!") }
                    switch formSection {
                    case .obstetricHistory:
                        let node = ASMedicalFormCellNode<TerminalCellNode<ObstetricHistory>>()
                        node.configure(with: item)
                        return node
                    case .menstrualHistory:
                        let node = ASMedicalFormCellNode<TerminalCellNode<MenstrualHistory>>()
                        node.configure(with: item)
                        return node
                    case .familyHistory:
                        let node = ASMedicalFormCellNode<TerminalCellNode<FamilyHistory>>()
                        node.configure(with: item)
                        return node
                    case .personalHistory:
                        let node = ASMedicalFormCellNode<TerminalCellNode<PersonalHistory>>()
                        node.configure(with: item)
                        return node
                    case .generalHistory:
                        let node = ASMedicalFormCellNode<TerminalCellNode<GeneralHistory>>()
                        node.configure(with: item)
                        return node
                    }
                case .pageBreak:
                    return ASPageBreakCellNode()
                }
            }
        }
        
        animatedDataSource = RxASTableAnimatedDataSource(configureCellBlock: configureCell)
        
        super.init(style: style)
        delegate = self
    }
    
    // MARK: Lifecycle methods
    
    override func didLoad() {
        super.didLoad()
    }
    
    // MARK: Instance methods
    
    internal func generateHeaderViewForSection(at index: Int) -> UIView {
        let text = animatedDataSource[index].medicalSection.displayTitle
        let font = UIFont.preferredPrintFont(forTextStyle: .callout)
        let attributedText = NSAttributedString(string: text, attributes: [.font: font])
        let width = frame.size.width
        let height = attributedText.height(withConstrainedWidth: width) + 8
        
        return UIView(frame: CGRect.zero).then {
            let label = UILabel(frame: CGRect(x: 8, y: 0, width: width, height: height)).then {
                $0.textColor = .white
                $0.font = font
                $0.text = text
            }
            $0.backgroundColor = .darkGray
            $0.addSubview(label)
        }
    }
    
    internal func getHeaderHeightForSection(at index: Int) -> CGFloat {
        let font = UIFont.preferredPrintFont(forTextStyle: .callout)
        let attributedText = NSAttributedString(string: "Random", attributes: [.font: font])
        let width = frame.size.width
        let height = attributedText.height(withConstrainedWidth: width)
        return height + 8
    }
}

// MARK: Undo and redo

extension ASAwareTableNode {
    func undo() {
        guard let indexPath = undoableActionsIndexes.popLast() else { return }
        guard let cellNode = nodeForRow(at: indexPath) as? CanvasCompatibleCellNode else { fatalError("Canvas view was not found") }
        guard let canvasView = cellNode.canvasNode.view as? CanvasView else { return }
        scrollToRow(at: indexPath, at: .middle, animated: true)
        canvasView.undo()
        cellNode.expand()
    }
    
    func redo() {
        guard let indexPath = redoableActionsIndexes.popLast() else { return }
        guard let cellNode = nodeForRow(at: indexPath) as? CanvasCompatibleCellNode else { return }
        guard let canvasView = cellNode.canvasNode.view as? CanvasView else { fatalError("Canvas view was not found") }
        scrollToRow(at: indexPath, at: .middle, animated: true)
        canvasView.redo()
        cellNode.expand()
    }
    
    func clear() {
        Array(0...numberOfSections - 1).forEach { section in
            Array(0...numberOfRows(inSection: section) - 1).forEach { row in
                let indexPath = IndexPath(row: row, section: section)
                guard let cellNode = nodeForRow(at: indexPath) as? CanvasCompatibleCellNode else { return }
                guard let canvasView = cellNode.canvasNode.view as? CanvasView else { fatalError("Canvas view was not found") }
                canvasView.clear()
            }
        }
        undoableActionsIndexes.removeAll()
        redoableActionsIndexes.removeAll()
    }
}

// MARK: Delegates

extension ASAwareTableNode: ASTableDelegate {
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return getHeaderHeightForSection(at: section)
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return generateHeaderViewForSection(at: section)
    }
    
    func tableNode(_ tableNode: ASTableNode, willDisplayRowWith node: ASCellNode) {
        if let medicalTermCellNode = node as? ASMedicalTermCellNode<TerminalCellNode<Symptom>> {
            medicalTermCellNode.linesChanged.debounce(0.3, scheduler: MainScheduler.instance)
                .subscribe(onNext: { [weak self] in self?.linesUpdateSubject.onNext($0) })
                .disposed(by: medicalTermCellNode.disposeBag)
        } else if let medicalTermCellNode = node as? ASMedicalTermCellNode<TerminalCellNode<Examination>> {
            medicalTermCellNode.linesChanged.debounce(0.3, scheduler: MainScheduler.instance)
                .subscribe(onNext: { [weak self] in self?.linesUpdateSubject.onNext($0) })
                .disposed(by: medicalTermCellNode.disposeBag)
        } else if let medicalTermCellNode = node as? ASMedicalTermCellNode<TerminalCellNode<Diagnosis>> {
            medicalTermCellNode.linesChanged.debounce(0.3, scheduler: MainScheduler.instance)
                .subscribe(onNext: { [weak self] in self?.linesUpdateSubject.onNext($0) })
                .disposed(by: medicalTermCellNode.disposeBag)
        } else if let medicalTermCellNode = node as? ASMedicalTermCellNode<TerminalCellNode<Prescription>> {
            medicalTermCellNode.linesChanged.debounce(0.3, scheduler: MainScheduler.instance)
                .subscribe(onNext: { [weak self] in self?.linesUpdateSubject.onNext($0) })
                .disposed(by: medicalTermCellNode.disposeBag)
        } else if let medicalTermCellNode = node as? ASMedicalTermCellNode<TerminalCellNode<Test>> {
            medicalTermCellNode.linesChanged.debounce(0.3, scheduler: MainScheduler.instance)
                .subscribe(onNext: { [weak self] in self?.linesUpdateSubject.onNext($0) })
                .disposed(by: medicalTermCellNode.disposeBag)
        } else if let medicalTermCellNode = node as? ASMedicalTermCellNode<TerminalCellNode<Procedure>> {
            medicalTermCellNode.linesChanged.debounce(0.3, scheduler: MainScheduler.instance)
                .subscribe(onNext: { [weak self] in self?.linesUpdateSubject.onNext($0) })
                .disposed(by: medicalTermCellNode.disposeBag)
        } else if let medicalTermCellNode = node as? ASMedicalTermCellNode<TerminalCellNode<Instruction>> {
            medicalTermCellNode.linesChanged.debounce(0.3, scheduler: MainScheduler.instance)
                .subscribe(onNext: { [weak self] in self?.linesUpdateSubject.onNext($0) })
                .disposed(by: medicalTermCellNode.disposeBag)
        } else if let medicalFormCellNode = node as? ASMedicalFormCellNode<TerminalCellNode<ObstetricHistory>> {
            medicalFormCellNode.linesChanged.debounce(0.3, scheduler: MainScheduler.instance)
                .subscribe(onNext: { [weak self] in self?.linesUpdateSubject.onNext($0) })
                .disposed(by: medicalFormCellNode.disposeBag)
        } else if let medicalFormCellNode = node as? ASMedicalFormCellNode<TerminalCellNode<MenstrualHistory>> {
            medicalFormCellNode.linesChanged.debounce(0.3, scheduler: MainScheduler.instance)
                .subscribe(onNext: { [weak self] in self?.linesUpdateSubject.onNext($0) })
                .disposed(by: medicalFormCellNode.disposeBag)
        } else if let medicalFormCellNode = node as? ASMedicalFormCellNode<TerminalCellNode<FamilyHistory>> {
            medicalFormCellNode.linesChanged.debounce(0.3, scheduler: MainScheduler.instance)
                .subscribe(onNext: { [weak self] in self?.linesUpdateSubject.onNext($0) })
                .disposed(by: medicalFormCellNode.disposeBag)
        } else if let medicalFormCellNode = node as? ASMedicalFormCellNode<TerminalCellNode<PersonalHistory>> {
            medicalFormCellNode.linesChanged.debounce(0.3, scheduler: MainScheduler.instance)
                .subscribe(onNext: { [weak self] in self?.linesUpdateSubject.onNext($0) })
                .disposed(by: medicalFormCellNode.disposeBag)
        } else if let medicalFormCellNode = node as? ASMedicalFormCellNode<TerminalCellNode<GeneralHistory>> {
            medicalFormCellNode.linesChanged.debounce(0.3, scheduler: MainScheduler.instance)
                .subscribe(onNext: { [weak self] in self?.linesUpdateSubject.onNext($0) })
                .disposed(by: medicalFormCellNode.disposeBag)
        }
    }
    
    /// Since ASAwareTableNode's delegate is HomeViewController. We have to do this so that ASAwareTableNode is aware of the scrolling.
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
    }
}
