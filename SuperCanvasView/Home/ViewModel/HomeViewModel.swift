//
//  HomeViewModel.swift
//  SuperCanvasView
//
//  Created by Krishna C Aluru on 10/6/18.
//  Copyright © 2018 Sourav Chandra. All rights reserved.
//

import Foundation
import RxDataSources
import ReactorKit
import RxSwift

final class HomeViewModel: Reactor {
    enum Action {
        case initialLoad
        case add(ConsultationRow)
        case addTen
        case deleteAll
    }
    
    enum Mutation {
        case appendTenConsultationRows
        case setPages([ConsultationPageSection])
    }
    
    struct State {
        var pages: [ConsultationPageSection] = []
        let pageHeight: Float = 300
    }
    
    let initialState = State()
    
    init() { }
    
    func mutate(action: HomeViewModel.Action) -> Observable<HomeViewModel.Mutation> {
        switch action {
        case .initialLoad: return mutateInitialLoad()
        case let .add(consultationRow): return mutateAppendConsultationRow(consultationRow)
        case .addTen: return .empty()
        case .deleteAll: return .just(.setPages([ConsultationPageSection(items: [])]))
        }
    }
    
    private func mutateInitialLoad() -> Observable<Mutation> {
        return .just(.setPages([ConsultationPageSection(items: [ConsultationRow(height: currentState.pageHeight, medicalSection: .none)])]))
    }
    
    private func mutateAppendConsultationRow(_ consultationRow: ConsultationRow) -> Observable<Mutation> {
        let consultationRows = currentState.pages.reduce([], { result, page in return result + page.items.filter { row in row.medicalSection != .none } })
        return .just(.setPages(createPages(for: consultationRows, appending: consultationRow)))
    }
    
    private func createPages(for consultationRows: [ConsultationRow], appending consultationRow: ConsultationRow) -> [ConsultationPageSection] {
        let pageHeight = currentState.pageHeight
        var consultationRows = consultationRows
        let indexToInsert = consultationRows.reduce(consultationRows.count, { result, row in
            guard consultationRow.medicalSection == row.medicalSection else { return result }
            if let index = consultationRows.firstIndex(of: row) { return index + 1 }
            return result
        })
        consultationRows.insert(consultationRow, at: indexToInsert)
        return consultationRows.reduce([], { result, row in
            var result = result
            guard !result.isEmpty else {
                let heightToBePadded = pageHeight - row.height
                let newItems = heightToBePadded != 0 ? [row, ConsultationRow(height: heightToBePadded, medicalSection: .none)] : [row]
                return [ConsultationPageSection(items: newItems)]
            }
            let fullResult = result
            var lastPage = result.removeLast()
            lastPage.items = lastPage.items.filter { item in item.medicalSection != .none }
            let usedHeight: Float = lastPage.items.reduce(0, { result, item in result + item.height })
            var heightToBePadded = pageHeight - usedHeight - row.height
            let canInsertInPage = row.height <= pageHeight - usedHeight
            guard canInsertInPage else {
                heightToBePadded = pageHeight - row.height
                let newItems = heightToBePadded != 0 ? [row, ConsultationRow(height: heightToBePadded, medicalSection: .none)] : [row]
                return fullResult + [ConsultationPageSection(items: newItems)]
            }
            let newItems = heightToBePadded != 0 ? [row, ConsultationRow(height: heightToBePadded, medicalSection: .none)] : [row]
            lastPage.items += newItems
            return result + [lastPage]
        })
    }
    
    func reduce(state: HomeViewModel.State, mutation: HomeViewModel.Mutation) -> HomeViewModel.State {
        var state = state
        switch mutation {
        case .appendTenConsultationRows:
            print("reached here")
        case let .setPages(pages):
            state.pages = pages
        }
        return state
    }
//    private func showPrint() {
//        var images: [UIImage] = []
//        for section in 0...tableView.numberOfSections - 1 {
//            for row in 0...tableView.numberOfRows(inSection: section) - 1 {
//                let indexPath = IndexPath(row: row, section: section)
//                tableView.scrollToRow(at: indexPath, at: .top, animated: false)
//                //                tableView.reloadData()
//                //                tableView.setNeedsLayout()
//                tableView.layoutIfNeeded()
//                let cell = tableView.cellForRow(at: indexPath)
//                cell?.swCapture { image in
//                    guard let `image` = image else { return }
//                    images.append(image)
//                }
//            }
//        }
//        printConsultation(images: images)
//    }
//
//    private func printConsultation(images: [UIImage]) {
//        let pi = UIPrintInfo(dictionary: nil)
//        pi.outputType = .general
//        pi.jobName = "JOB"
//        pi.orientation = .portrait
//        pi.duplex = .longEdge
//        let pic = UIPrintInteractionController.shared
//        pic.printInfo = pi
//        pic.printingItems = images
//        pic.present(animated: true)
//    }
}
