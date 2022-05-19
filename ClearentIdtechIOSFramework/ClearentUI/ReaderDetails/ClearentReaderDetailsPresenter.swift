//
//  ClearentReaderDetailsPresenter.swift
//  ClearentIdtechIOSFramework
//
//  Created by Carmen Jurcovan on 17.05.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

public protocol ClearentReaderDetailsProtocol {
    var readerInfo: ReaderInfo { get set }
    func removeReader()
    func handleConnection(shouldConnect: Bool)
    func handleAutojoin(markAsAutojoin: Bool)
}

public class ClearentReaderDetailsPresenter: ClearentReaderDetailsProtocol {
    public var readerInfo: ReaderInfo

    public init(readerInfo: ReaderInfo) {
        self.readerInfo = readerInfo
        ClearentWrapper.shared.searchRecentlyUsedReaders()
    }

    public func removeReader() {
        if readerInfo.isConnected {
            ClearentWrapper.shared.disconnectFromReader()
        }
        ClearentWrapper.shared.removeReaderFromRecentlyUsed(reader: readerInfo)
    }

    public func handleConnection(shouldConnect: Bool) {
        if shouldConnect {
            ClearentWrapper.shared.connectTo(reader: readerInfo)
        } else {
            ClearentWrapper.shared.disconnectFromReader()
        }
    }

    public func handleAutojoin(markAsAutojoin: Bool) {
        var previousReaderWithAutojoin = ClearentWrapperDefaults.recentlyPairedReaders?.first { $0.autojoin == true }
        previousReaderWithAutojoin?.autojoin = false
        readerInfo.autojoin = markAsAutojoin
    }
}
