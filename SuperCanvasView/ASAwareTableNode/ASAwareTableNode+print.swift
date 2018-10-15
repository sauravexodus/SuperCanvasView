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
    func generatePages(_ pageHeight: CGFloat) -> Observable<[UIImage]> {
        return Observable<Int>.interval(0.01, scheduler: MainScheduler.instance)
            .take(numberOfSections)
            .concatMap { [weak self] section -> Observable<UIImage?> in
                guard let strongSelf = self else { return .just(nil) }
                return strongSelf.captureSinglePage(section)
            }
            .unwrap()
            .reduce([], accumulator: { pages, image -> [(image: UIImage, height: CGFloat)] in
                var `pages` = pages
                guard let lastPage = pages.last else { return [(image, image.size.height)] }
                if lastPage.height + image.size.height > pageHeight {
                    return pages + [(image, image.size.height)]
                } else {
                    guard let newImage = [lastPage.image, image].mergeToSingleImage() else { return pages }
                    let _ = pages.popLast()
                    return pages + [(newImage, newImage.size.height)]
                }
            })
            .map { $0.map { $0.image.padToPage(of: pageHeight) } }
            .do(onDispose: { [weak self] in
                self?.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
            })
    }
    
    private func captureSinglePage(_ section: Int) -> Observable<UIImage?> {
        return Observable<Int>.interval(0.01, scheduler: MainScheduler.instance)
            .take(numberOfRows(inSection: section))
            .concatMap { [weak self] row -> Observable<UIImage?> in
                guard let strongSelf = self else { return .just(nil) }
                let indexPath = IndexPath(row: row, section: section)
                if strongSelf.animatedDataSource.sectionModels[section].items[row].isTerminal || strongSelf.animatedDataSource.sectionModels[section].items[row].isPageBreak { return .just(nil) }
                strongSelf.scrollToRow(at: indexPath, at: .top, animated: true)
                let cell = strongSelf.cellForRow(at: indexPath)
                return cell?.contentView.rx.swCapture() ?? .just(nil)
            }
    }
}
