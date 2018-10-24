//
//  ASAwareTableNode+print.swift
//  SuperCanvasView
//
//  Created by Sourav Chandra on 12/10/18.
//  Copyright © 2018 Sourav Chandra. All rights reserved.
//

import Foundation
import RxSwift

// MARK: Printing

extension ASAwareTableNode {
    func contract() -> Observable<Void> {
        scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: false)
        return Observable<Int>.interval(0.2, scheduler: MainScheduler.instance)
            .take(numberOfSections)
            .concatMap { [weak self] section -> Observable<Void> in
                guard let strongSelf = self else { return .just(()) }
                return Observable<Int>.interval(0.1, scheduler: MainScheduler.instance)
                    .take(strongSelf.numberOfRows(inSection: section))
                    .concatMap { [weak self] row -> Observable<Void> in
                        guard let strongSelf = self else { return .just(()) }
                        let indexPath = IndexPath(row: row, section: section)
                        if section >= strongSelf.numberOfSections || row >= strongSelf.numberOfRows(inSection: section) { return .just(()) }
                        if strongSelf.animatedDataSource.sectionModels[section].items[row].isTerminal || strongSelf.animatedDataSource.sectionModels[section].items[row].isPageBreak { return .just(()) }
                        strongSelf.scrollToRow(at: indexPath, at: .top, animated: false)
                        guard let node = strongSelf.nodeForRow(at: indexPath) as? ExpandableCellNode else {
                            return .just(())
                        }
                        node.contract(interactionType: .scribble)
                        return .just(())
                }
            }
            .reduce(0, accumulator: { acc, _ in acc + 1 })
            .mapTo(())
            .do(onDispose: { [weak self] in
                self?.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: false)
            })
    }

    func generatePages() -> Observable<[UIImage]> {
        scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: false)
        return Observable<Int>.interval(0.1, scheduler: MainScheduler.instance)
            .take(numberOfSections)
            .concatMap { [weak self] section -> Observable<UIImage?> in
                guard let strongSelf = self else { return .just(nil) }
                return strongSelf.captureSinglePage(section)
            }
            .unwrap()
            .reduce([], accumulator: { pages, image -> [(image: UIImage, height: CGFloat)] in
                var `pages` = pages
                guard let lastPage = pages.last else { return [(image, image.size.height)] }
                if lastPage.height + image.size.height > PageSize.selectedPage.heightRemovingMargins {
                    return pages + [(image, image.size.height)]
                } else {
                    guard let newImage = [lastPage.image, image].mergeToSingleImage() else { return pages }
                    let _ = pages.popLast()
                    return pages + [(newImage, newImage.size.height)]
                }
            })
            .map { $0.map { $0.image.padToPage(of: PageSize.selectedPage.heightRemovingMargins, width: PageSize.selectedPage.widthRemovingMargins) } }
            .do(onDispose: { [weak self] in
                self?.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: false)
            })
    }
    
    private func captureSinglePage(_ section: Int) -> Observable<UIImage?> {
        let cellImageObservables = Observable<Int>.interval(0.08, scheduler: MainScheduler.instance)
            .take(numberOfRows(inSection: section))
            .concatMap { [weak self] row -> Observable<UIImage?> in
                guard let strongSelf = self else { return .just(nil) }
                let indexPath = IndexPath(row: row, section: section)
                if strongSelf.animatedDataSource.sectionModels[section].items[row].isTerminal || strongSelf.animatedDataSource.sectionModels[section].items[row].isPageBreak { return .just(nil) }
                strongSelf.scrollToRow(at: indexPath, at: .top, animated: false)
                let cell = strongSelf.cellForRow(at: indexPath)
                return cell?.contentView.rx.swCapture() ?? .just(nil)
            }
        var view = generateHeaderViewForSection(at: section)
        let rect = CGRect(x: 0, y: 0, width: PageSize.selectedPage.widthRemovingMargins, height: getHeaderHeightForSection(at: section))
        view.frame = rect
        return .concat(view.rx.swCapture(),  cellImageObservables)
    }
}
