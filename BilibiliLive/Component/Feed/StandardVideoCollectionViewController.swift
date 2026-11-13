//
//  StandardVideoCollectionViewController.swift
//  BilibiliLive
//
//  Created by yicheng on 2022/11/5.
//

import UIKit

protocol PlayableData: DisplayData {
    var aid: Int { get }
    var cid: Int { get }
}

class StandardVideoCollectionViewController<T: PlayableData>: UIViewController, BLTabBarContentVCProtocol {
    let collectionVC = FeedCollectionViewController()
    var lastReloadDate = Date()
    var reloadInterval: TimeInterval = 60 * 60
    var reloading = false
    private var page = 0
    private var loadGeneration = 0
    override var preferredFocusEnvironments: [UIFocusEnvironment] {
        return [collectionVC.collectionView]
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCollectionView()
        collectionVC.show(in: self)
        reloadData()
        NotificationCenter.default.addObserver(self, selector: #selector(didBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        autoReloadIfNeed()
    }

    func setupCollectionView() {
        collectionVC.pageSize = 20
        collectionVC.didSelect = {
            [weak self] in
            self?.goDetail(with: $0 as! T)
        }
        collectionVC.loadMore = {
            [weak self] in
            self?.loadMore()
        }
        if supportVideoQuickActions() {
            collectionVC.didLongPress = {
                [weak self] record in
                guard let self, let record = record as? T else { return }
                VideoQuickActionMenu.shared.present(aid: record.aid, title: record.title, from: self)
            }
        }
    }

    func supportPullToLoad() -> Bool {
        return true
    }

    /// 长按视频时是否弹出视频快捷操作菜单（加入稍后再看 / 收藏视频 / 不感兴趣）
    func supportVideoQuickActions() -> Bool {
        return false
    }

    func request(page: Int) async throws -> [T] {
        return [T]()
    }

    func goDetail(with record: T) {
        let detailVC = VideoDetailViewController.create(aid: record.aid, cid: record.cid)
        detailVC.present(from: self)
    }

    func reloadData() {
        Task {
            await reallyReloadData()
        }
    }

    func reallyReloadData() async {
        if reloading { return }
        reloading = true
        loadGeneration += 1
        let generation = loadGeneration
        collectionVC.finishLoadingMore()
        reloadStateDidChange()
        defer {
            reloading = false
            reloadStateDidChange()
        }
        do {
            let res = try await request(page: 1)
            guard generation == loadGeneration else { return }
            page = 1
            lastReloadDate = Date()
            collectionVC.finishLoadingMore()
            collectionVC.displayDatas = []
            collectionVC.appendData(displayData: res)
        } catch let err {
            let alert = UIAlertController(title: "Error", message: "\(err)", preferredStyle: .alert)
            alert.addAction(.init(title: "Ok", style: .cancel))
            present(alert, animated: true)
        }
    }

    func reloadStateDidChange() {}

    // MARK: - Private

    private func loadMore() {
        guard supportPullToLoad(), !reloading else {
            collectionVC.finishLoadingMore()
            return
        }
        let generation = loadGeneration
        let nextPage = page + 1
        Task {
            do {
                let res = try await request(page: nextPage)
                guard generation == loadGeneration else { return }
                collectionVC.appendData(displayData: res)
                page = nextPage
            } catch {
                guard generation == loadGeneration else { return }
                collectionVC.finishLoadingMore()
            }
        }
    }

    func autoReloadIfNeed() {
        guard isViewLoaded, view.window != nil else { return }
        guard Date().timeIntervalSince(lastReloadDate) > reloadInterval else { return }
        Task {
            await reallyReloadData()
        }
    }

    @objc private func didBecomeActive() {
        autoReloadIfNeed()
    }
}
