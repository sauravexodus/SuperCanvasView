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
        case select(MedicalSection)
        case add(MedicalTermType)
        case updateHeights([IndexPathWithHeight])
        case deleteAll
    }
    
    enum Mutation {
        case setPages([ConsultationPageSection])
        case setFocusedIndexPath(IndexPathWithScrollPosition)
    }
    
    struct State {
        var pages: [ConsultationPageSection] = []
        let pageHeight: CGFloat = 300
        var focusedIndexPath: IndexPathWithScrollPosition?
    }
    
    let initialState = State()
    
    init() { }
    
    func mutate(action: HomeViewModel.Action) -> Observable<HomeViewModel.Mutation> {
        switch action {
        case .initialLoad: return mutateInitialLoad()
        case let .select(medicalSection): return mutateSelectMedicalSection(medicalSection)
        case let .add(medicalTerm): return mutateAppendMedicalTerm(medicalTerm)
        case let .updateHeights(newHeights): return mutateUpdateHeights(newHeights)
        case .deleteAll: return mutateInitialLoad()
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
        return .just(.setPages([ConsultationPageSection(items: [ConsultationRow(height: currentState.pageHeight, lines: [Line](), medicalTerm: Symptom(name: nil), needsHeader: true)], pageHeight: currentState.pageHeight)]))
    }
    
    private func mutateSelectMedicalSection(_ medicalSection: MedicalSection) -> Observable<Mutation> {
        let indexPath = currentState.pages.enumerated()
            .reduce([], { result, page in
                return result + page.element.items.enumerated().map { offset, item in
                    return (sectionIndex: page.offset, itemIndex: offset, item: item)
                }
            })
            .first { sectionIndex, itemIndex, item in
                item.medicalTerm.sectionOfSelf == medicalSection
            }
            .map { sectionIndex, itemIndex, _ in
                IndexPathWithScrollPosition(
                    indexPath: IndexPath(row: itemIndex, section: sectionIndex),
                    scrollPosition: .top)
            }
        guard let foundPath = indexPath else { return .empty() }
        return .just(.setFocusedIndexPath(foundPath))
    }
    
    private func mutateAppendMedicalTerm(_ medicalTerm: MedicalTermType) -> Observable<Mutation> {
        let consultationRows = currentState.pages.reduce([], { result, page in return result + page.items.filter { row in !row.isPadder } })
        let consultationRow = ConsultationRow(height: 50, lines: [], medicalTerm: medicalTerm)
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
        heights.forEach { result in
            pages[result.indexPath.section].items[result.indexPath.row].height = result.height
        }
        let consultationRows = pages.reduce([], { result, page in return result + page.items.filter { row in !row.isPadder } })
        return .just(.setPages(createPages(for: consultationRows)))
    }
}

// MARK: Helpers

extension HomeViewModel {
    private func createPages(for consultationRows: [ConsultationRow], appending consultationRow: ConsultationRow) -> [ConsultationPageSection] {
        var consultationRows = consultationRows
        var consultationRow = consultationRow
        // find index to insert the new row in
        let indexToInsert = consultationRows.reduce(consultationRows.count, { result, row in
            guard consultationRow.medicalTerm.sectionOfSelf == row.medicalTerm.sectionOfSelf else {
                return result
            }
            if let index = consultationRows.index(of: row) { return index + 1 }
            return result
        })
        // set needs header if it is the first item of it's kind
        consultationRow.needsHeader = indexToInsert == 0 || !(consultationRows[indexToInsert - 1].medicalTerm.sectionOfSelf == consultationRow.medicalTerm.sectionOfSelf)
        // insert new medical term into consultation rows
        consultationRows.insert(consultationRow, at: indexToInsert)
        // create pages after inserting row
        let pages = consultationRows.reduce([], { result, row -> [ConsultationPageSection] in
            var result = result
            guard !result.isEmpty else { return [ConsultationPageSection(items: [row], pageHeight: currentState.pageHeight)] }
            let fullResult = result
            var lastPage = result.removeLast()
            guard lastPage.canInsertRow(with: row.height) else { return fullResult + [ConsultationPageSection(items: [row], pageHeight: currentState.pageHeight)] }
            lastPage.items += [row]
            return result + [lastPage]
        })
        // pad the pages and return them
        return padPages(pages)
    }
    
    private func createPages(for consultationRows: [ConsultationRow]) -> [ConsultationPageSection] {
        let pages = consultationRows.reduce([], { result, row -> [ConsultationPageSection] in
            var result = result
            guard !result.isEmpty else { return [ConsultationPageSection(items: [row], pageHeight: currentState.pageHeight)] }
            let fullResult = result
            var lastPage = result.removeLast()
            guard lastPage.canInsertRow(with: row.height) else { return fullResult + [ConsultationPageSection(items: [row], pageHeight: currentState.pageHeight)] }
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
            pagesCopy[index] = ConsultationPageSection(items: page.items + newItems, pageHeight: currentState.pageHeight)
        }
        if let lastPage = pages.last, let nextPage = lastPage.nextPage {
            pagesCopy.append(nextPage)
        }
        return pagesCopy
    }
}
