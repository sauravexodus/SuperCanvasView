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
import RxCocoa
import RxGesture
import RxASDataSources

extension Reactive where Base: UIScrollView {
    func swCapture() -> Observable<UIImage?> {
        return Observable.create { [weak base] observer in
            guard let strongBase = base else {
                observer.onError(NSError.init(domain: "Failed to get base", code: 0, userInfo: nil))
                return Disposables.create()
            }
            strongBase.swContentCapture({ (image) in
                observer.onNext(image)
                observer.onCompleted()
            })
            return Disposables.create()
        }
    }
}

extension Reactive where Base: UIView {
    func swCapture() -> Observable<UIImage?> {
        return Observable.create { [weak base] observer in
            guard let strongBase = base else {
                observer.onError(NSError.init(domain: "Failed to get base", code: 0, userInfo: nil))
                return Disposables.create()
            }
            strongBase.swCapture({ (image) in
                observer.onNext(image)
                observer.onCompleted()
            })
            return Disposables.create()
        }
    }
}

extension CGSize {
    init(width: Float, height: Float) {
        self.init(width: CGFloat(width), height: CGFloat(height))
    }
}

extension UIView {
    var asNode: ASDisplayNode {
        return ASDisplayNode.init(viewBlock: { () -> UIView in
            return self
        }, didLoad: nil)
    }
}

extension Reactive where Base: ASDisplayNode {
    var tap: Observable<UITapGestureRecognizer> {
        return base.view.rx.tapGesture().when(.recognized)
    }
}

final class ASDisplayNodeWithBackgroundColor: ASDisplayNode {
    
    init(color: UIColor) {
        super.init()
        backgroundColor = color
    }
    
}

final class ContainerDisplayNode: ASDisplayNode {
    
    let addMedicaltermButtonNode = ASButtonNode().then {
        $0.setTitle("Add", with: nil, with: .white, for: .normal)
        $0.style.preferredSize.width = 100
    }
    
    let deleteAllRowsButtonNode = ASButtonNode().then {
        $0.setTitle("Delete All", with: nil, with: .white, for: .normal)
        $0.style.preferredSize.width = 140
    }
    
    let printButtonNode = ASButtonNode().then {
        $0.setTitle("Print", with: nil, with: .white, for: .normal)
        $0.style.preferredSize.width = 100
    }
    
    let tableNode = ASTableNode(style: .plain).then {
        $0.view.panGestureRecognizer.allowedTouchTypes = [NSNumber(value: UITouchType.direct.rawValue)]
        $0.view.tableFooterView = UIView()
        $0.view.backgroundColor = .yellow
        $0.style.flexGrow = 1
    }
    
    override init() {
        super.init()
        backgroundColor = .black
        automaticallyManagesSubnodes = true
    }
    
    override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        let mainStack: ASStackLayoutSpec = .vertical()
        
        let spacer = ASLayoutSpec()
        spacer.style.flexGrow = 1
        
        let buttonsStack: ASStackLayoutSpec = .horizontal()
        buttonsStack.spacing = 8
        
        let backgroundColor = ASDisplayNodeWithBackgroundColor(color: .black)
        let backgroundSpec = ASBackgroundLayoutSpec(child: buttonsStack, background: backgroundColor)
        
        buttonsStack.style.preferredSize.height = 80
        buttonsStack.children = [addMedicaltermButtonNode, deleteAllRowsButtonNode, printButtonNode, spacer]
        
        mainStack.children = [backgroundSpec, tableNode]
        return mainStack
    }
    
}

final class ASHomeViewController: ASViewController<ContainerDisplayNode>, ReactorKit.View {

    var disposeBag: DisposeBag = DisposeBag()
    let dataSource: RxASTableReloadDataSource<ConsultationPageSection>
    let containerNode = ContainerDisplayNode()
    
    
    init(viewModel: HomeViewModel) {
        defer { self.reactor = viewModel }
        
        let configureCell: RxASTableReloadDataSource<ConsultationPageSection>.ConfigureCellBlock = { (ds, tableNode, index, item) in
            return { () -> ASCellNode in
                let cellNode = ASCellNode(viewBlock: { () -> UIView in
                    let view = ASMedicalTermCellNode()
                    view.configure(with: "\(item.medicalSection.name ?? "Empty") (\(index.section), \(index.row))", and: [])
                    return view
                })
                cellNode.style.preferredSize = CGSize(width: Float.greatestFiniteMagnitude, height: item.height)
                return cellNode
            }
        }
        
        dataSource = RxASTableReloadDataSource(configureCellBlock: configureCell)

        super.init(node: containerNode)
        containerNode.frame = self.view.bounds
        containerNode.view.backgroundColor = .white
        containerNode.tableNode.delegate = self
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Layout
    
    
    
    // MARK: Bindings
    
    func bind(reactor: HomeViewModel) {
        bindActions(reactor: reactor)
        bindState(reactor: reactor)
    }
    
    private func bindActions(reactor: HomeViewModel) {
        rx.viewDidAppear
            .mapTo(.initialLoad)
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        containerNode.addMedicaltermButtonNode.rx
            .tap
            .map { _ in
                let heightsArray = [50, 100, 150]
                let randomHeightIndex = Int(arc4random_uniform(UInt32(heightsArray.count)))
                let medicalSectionsArray = [MedicalSection.symptoms(name: "Symptom", lines: []), MedicalSection.diagnoses(name: "Diagnosis", lines: [])]
                let randomSectionIndex = Int(arc4random_uniform(UInt32(medicalSectionsArray.count)))
                return .add(ConsultationRow(height: Float(heightsArray[randomHeightIndex]), medicalSection: medicalSectionsArray[randomSectionIndex]))
            }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        containerNode.deleteAllRowsButtonNode.rx
            .tap
            .mapTo(.deleteAll)
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        containerNode.printButtonNode.rx.tap
            .flatMap { [weak self] _ -> Observable<[UIImage]> in
                guard let strongSelf = self  else { return .empty() }
                return strongSelf.generateImages()
            }
            .map { .print($0) }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
    }
    
    private func bindState(reactor: HomeViewModel) {
        reactor.state.map { $0.pages }
            .bind(to: containerNode.tableNode.rx.items(dataSource: dataSource))
            .disposed(by: disposeBag)
    }
    
    private func generateImages() -> Observable<[UIImage]> {
        return Observable<Int>.interval(0.2, scheduler: MainScheduler.instance)
            .take(containerNode.tableNode.numberOfSections)
            .concatMap { [weak self] section -> Observable<UIImage?> in
                guard let strongSelf = self else { return .just(nil) }
                return Observable.from(Array(0...strongSelf.containerNode.tableNode.numberOfRows(inSection: section) - 1))
                    .concatMap { row -> Observable<UIImage?> in
                        let indexPath = IndexPath(row: row, section: section)
                        strongSelf.containerNode.tableNode.scrollToRow(at: indexPath, at: .top, animated: true)
                        let cell = strongSelf.containerNode.tableNode.cellForRow(at: indexPath)
                        return cell?.contentView.rx.swCapture() ?? .just(nil)
                    }
                    .unwrap()
                    .reduce([], accumulator: { images, image in
                        var `images` = images
                        images.append(image)
                        return images
                    })
                    .map { $0.mergeToSingleImage() }
            }
            .unwrap()
            .reduce([], accumulator: { images, page in
                var `images` = images
                images.append(page)
                return images
            })
            .do(onDispose: { [weak self] in
                self?.containerNode.tableNode.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
            })
    }
}

extension ASHomeViewController: ASTableDelegate {
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 16
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView()
        view.backgroundColor = .gray
        return view
    }
    
}
