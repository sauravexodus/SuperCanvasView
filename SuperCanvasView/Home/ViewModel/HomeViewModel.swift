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
    typealias IndexPathWithScrollPosition = (indexPath: IndexPath, scrollPosition: UITableViewScrollPosition)
    typealias IndexPathWithHeight = (indexPath: IndexPath, height: CGFloat)

    enum Action {
        case initialLoad
        case updateLines(indexPath: IndexPath, lines: [Line])
        case select(MedicalSection)
        case add(MedicalTermType)
        case updateHeights([IndexPathWithHeight])
        case deleteAll
        case print([UIImage])
    }
    
    enum Mutation {
        case setPages([ConsultationPageSection])
        case setFocusedIndexPath(IndexPathWithScrollPosition)
    }
    
    struct State {
        var pages: [ConsultationPageSection] = []
        let pageHeight: CGFloat = 842
        var focusedIndexPath: IndexPathWithScrollPosition?
    }
    
    let initialState = State()
    
    func mutate(action: HomeViewModel.Action) -> Observable<HomeViewModel.Mutation> {
        switch action {
        case .initialLoad: return mutateInitialLoad()
        case let .select(medicalSection): return mutateSelectMedicalSection(medicalSection)
        case let .add(medicalTerm): return mutateAppendMedicalTerm(medicalTerm)
        case let .updateHeights(newHeights): return mutateUpdateHeights(newHeights)
        case .deleteAll: return mutateInitialLoad()
        case let .updateLines(indexPath, lines): return mutateUpdatingLines(at: indexPath, lines: lines)
        case let .print(images): return mutatePrint(images: images)
        }
    }
    
    func reduce(state: HomeViewModel.State, mutation: HomeViewModel.Mutation) -> HomeViewModel.State {
        var state = state
        switch mutation {
        case let .setPages(pages):
            state.pages = pages
        case let .setFocusedIndexPath(indexPath):
            state.focusedIndexPath = indexPath
        }
        return state
    }
}

// MARK: Mutations

extension HomeViewModel {
    private func mutateInitialLoad() -> Observable<Mutation> {
        return .just(.setPages([ConsultationPageSection(items: [ConsultationRow(height: currentState.pageHeight, lines: [Line](), medicalTerm: Symptom(name: nil), needsHeader: true)], pageHeight: currentState.pageHeight, pageIndex: 0)]))
    }
    
    private func mutateUpdatingLines(at indexPath: IndexPath, lines: [Line]) -> Observable<Mutation> {
        var item = currentState.pages[indexPath.section].items[indexPath.row]
        item.lines = lines
        var newPages = currentState.pages
        newPages[indexPath.section].items[indexPath.row] = item
        return .just(.setPages(newPages))
    }
    
    private func mutateSelectMedicalSection(_ medicalSection: MedicalSection) -> Observable<Mutation> {
        let currentSectionItems = currentState.pages.enumerated()
            .reduce([], { result, page in
                return result + page.element.items.enumerated().map { offset, item in
                    return (sectionIndex: page.offset, itemIndex: offset, item: item)
                }
            })
            .filter {
                sectionIndex, itemIndex, item in item.medicalTerm.sectionOfSelf == medicalSection
            }

        guard let firstRow = currentSectionItems.first else { return .empty() }
        guard let lastRow = currentSectionItems.last else { return .empty() }
        var mutations: [Observable<Mutation>] = []
        
        var dummyRow = ConsultationRow(height: nil, lines: [], medicalTerm: medicalSection.correspondingEmptyTerm)
        dummyRow.medicalTerm.name = "A"
        let threshold = dummyRow.intrinsicContentHeight
        
        if (lastRow.item.isPadder && lastRow.item.height < threshold) || !lastRow.item.isPadder {
            var medicalTerm = lastRow.item.medicalTerm
            medicalTerm.name = nil
            mutations.append(mutateAppendMedicalTerm(medicalTerm))
        } else {
            let consultationRows = currentState.pages.reduce([], { result, page in return result + page.items.filter { row in !row.isPadder } })
            let pages = createPages(for: consultationRows)

            mutations.append(.just(.setPages(pages)))
        }
        
        let indexPath = IndexPathWithScrollPosition(
            indexPath: IndexPath(row: firstRow.itemIndex, section: firstRow.sectionIndex),
            scrollPosition: .top
        )
        
        mutations.append(.just(.setFocusedIndexPath(indexPath)))
        return Observable.concat(mutations)
    }
    
    private func mutateAppendMedicalTerm(_ medicalTerm: MedicalTermType) -> Observable<Mutation> {
        let consultationRows = currentState.pages.reduce([], { result, page in return result + page.items.filter { row in !row.isPadder } })
        let consultationRow = ConsultationRow(height: nil, lines: [], medicalTerm: medicalTerm)
        let pages = createPages(for: consultationRows, appending: consultationRow)
        let indexPath = pages.enumerated()
            .reduce([], { result, page in
                return result + page.element.items.enumerated().map { offset, item in
                    return (sectionIndex: page.offset, itemIndex: offset, item: item)
                }
            })
            .first { sectionIndex, itemIndex, item in
                item == consultationRow
            }
            .map { sectionIndex, itemIndex, item in
                IndexPathWithScrollPosition(indexPath: IndexPath(row: itemIndex, section: sectionIndex), scrollPosition: .none)
            }
        guard let foundPath = indexPath else { return .empty() }
        return .concat(.just(.setPages(pages)), .just(.setFocusedIndexPath(foundPath)))
    }
    
    private func mutateUpdateHeights(_ heights: [IndexPathWithHeight]) -> Observable<Mutation> {
        var pages = currentState.pages
        guard !pages.isEmpty else { return .empty() }
        heights.forEach { result in
            pages[result.indexPath.section].items[result.indexPath.row].height = result.height
        }
        let consultationRows = pages.reduce([], { result, page in return result + page.items.filter { row in !row.isPadder } })
        return .just(.setPages(createPages(for: consultationRows)))
    }
    
    private func mutatePrint(images: [UIImage]) -> Observable<Mutation> {
        let pi = UIPrintInfo(dictionary: nil)
        pi.outputType = .general
        pi.jobName = "JOB"
        pi.orientation = .portrait
        pi.duplex = .longEdge
        let pic = UIPrintInteractionController.shared
        pic.printInfo = pi
        pic.printingItems = images
        pic.present(animated: true)
        return .empty()
    }
}

// MARK: Helpers

extension HomeViewModel {
    private func createPages(for consultationRows: [ConsultationRow], appending consultationRow: ConsultationRow) -> [ConsultationPageSection] {
        var consultationRows = consultationRows
        var consultationRow = consultationRow
        // find index to insert the new row in
        let indexToInsert = consultationRows.reduce(consultationRows.count, { result, row in
            guard consultationRow.medicalTerm.sectionOfSelf == row.medicalTerm.sectionOfSelf else { return result }
            if let index = consultationRows.index(of: row) { return index + 1 }
            return result
        })
        // set needs header if it is the first item of it's kind
        consultationRow.needsHeader = indexToInsert == 0 || !(consultationRows[indexToInsert - 1].medicalTerm.sectionOfSelf == consultationRow.medicalTerm.sectionOfSelf)
        // insert new medical term into consultation rows
        consultationRows.insert(consultationRow, at: indexToInsert)
        // create pages after inserting row
        return createPages(for: consultationRows)
    }
    
    private func createPages(for consultationRows: [ConsultationRow]) -> [ConsultationPageSection] {
        let pages = consultationRows.reduce([], { result, row -> [ConsultationPageSection] in
            var result = result
            guard !result.isEmpty else { return [ConsultationPageSection(items: [row], pageHeight: currentState.pageHeight, pageIndex: 0)] }
            let fullResult = result
            var lastPage = result.removeLast()
            guard lastPage.canInsertRow(with: row.height) else { return fullResult + [ConsultationPageSection(items: [row], pageHeight: currentState.pageHeight, pageIndex: lastPage.pageIndex + 1)] }
            lastPage.items += [row]
            return result + [lastPage]
        })
        // pad the pages and return them
        return padPages(pages)
    }
    
    private func padPages(_ pages: [ConsultationPageSection]) -> [ConsultationPageSection] {
        var pagesCopy = pages
        for (index, page) in pages.enumerated() {
            var newItems: [ConsultationRow] = []
            if let paddingRow = page.paddingRow { newItems = [paddingRow] }
            pagesCopy[index] = ConsultationPageSection(items: page.items + newItems, pageHeight: currentState.pageHeight, pageIndex: index)
        }
        if let lastPage = pages.last, let nextPage = lastPage.nextPage {
            pagesCopy.append(nextPage)
        }
        return pagesCopy
    }
}

// MARK: Debugging

#if DEBUG

extension HomeViewModel {
    func transform(state: Observable<HomeViewModel.State>) -> Observable<HomeViewModel.State> {
        return state.debug("HomeViewModel", trimOutput: true)
    }
}

#endif
