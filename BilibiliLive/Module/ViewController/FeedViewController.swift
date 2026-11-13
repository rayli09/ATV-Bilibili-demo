//
//  FeedViewController.swift
//  BilibiliLive
//
//  Created by yicheng on 2021/5/19.
//

import UIKit

class FeedViewController: StandardVideoCollectionViewController<ApiRequest.FeedResp.Items> {
    override func setupCollectionView() {
        super.setupCollectionView()
        collectionVC.pageSize = 1
        collectionVC.showHeader = true
        collectionVC.customHeaderConfig = FeedHeaderConfig(viewType: FeedRefreshHeader.self, estimatedHeight: 90) { [weak self] header, _ in
            header.setRefreshing(self?.reloading ?? false)
            header.onRefresh = { [weak self] in self?.reloadData() }
        }
    }

    override func reloadStateDidChange() {
        guard isViewLoaded, let collectionView = collectionVC.collectionView else { return }
        collectionView.visibleSupplementaryViews(ofKind: String(describing: FeedRefreshHeader.self))
            .compactMap { $0 as? FeedRefreshHeader }
            .forEach { $0.setRefreshing(reloading) }
    }

    override func supportVideoQuickActions() -> Bool {
        return true
    }

    override func request(page: Int) async throws -> [ApiRequest.FeedResp.Items] {
        if page == 1 {
            return try await ApiRequest.getFeeds()
        } else if let last = (collectionVC.displayDatas.last as? ApiRequest.FeedResp.Items)?.idx {
            return try await ApiRequest.getFeeds(lastIdx: last)
        } else {
            throw NSError(domain: "", code: -1)
        }
    }
}

private final class FeedRefreshHeader: UICollectionReusableView {
    var onRefresh: (() -> Void)?
    private let button = UIButton(type: .system)

    override init(frame: CGRect) {
        super.init(frame: frame)
        var configuration = UIButton.Configuration.plain()
        configuration.image = UIImage(systemName: "arrow.clockwise")
        configuration.imagePadding = 12
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 22, bottom: 10, trailing: 22)
        button.configuration = configuration
        button.addTarget(self, action: #selector(refreshTapped), for: .primaryActionTriggered)
        addSubview(button)
        button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            button.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            button.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
        setRefreshing(false)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func setRefreshing(_ refreshing: Bool) {
        button.configuration?.title = refreshing ? "正在刷新…" : "刷新推荐"
        button.isEnabled = !refreshing
    }

    @objc private func refreshTapped() { onRefresh?() }
}

extension ApiRequest.FeedResp.Items: PlayableData {
    var aid: Int { Int(param) ?? 0 }
    var cid: Int { player_args?.cid ?? 0 }
}
