//
//  BLSettingLineCollectionViewCell.swift
//  BilibiliLive
//
//  Created by yicheng on 2022/10/29.
//

import UIKit

class BLSettingLineCollectionViewCell: BLMotionCollectionViewCell {
    let effectView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
    let selectedWhiteView = UIView()
    let iconImageView = UIImageView()
    let titleLabel = UILabel()
    override var isSelected: Bool {
        didSet {
            updateView()
        }
    }

    override func setup() {
        super.setup()
        scaleFactor = 1.03
        contentView.addSubview(effectView)
        effectView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        effectView.layer.cornerRadius = 12
        effectView.layer.cornerCurve = .continuous
        effectView.clipsToBounds = true
        selectedWhiteView.backgroundColor = UIColor.white
        selectedWhiteView.isHidden = !isFocused
        effectView.contentView.addSubview(selectedWhiteView)
        selectedWhiteView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        effectView.contentView.addSubview(iconImageView)
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(20)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(32)
        }
        effectView.contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(iconImageView.snp.trailing).offset(14)
            make.trailing.equalToSuperview().offset(-20)
            make.top.bottom.equalToSuperview().inset(8)
        }
        titleLabel.textAlignment = .left
        titleLabel.font = UIFont.systemFont(ofSize: 32, weight: .semibold)
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.minimumScaleFactor = 0.8
        titleLabel.textColor = .white
        effectView.layer.borderWidth = 1
        effectView.layer.borderColor = UIColor.white.withAlphaComponent(0.12).cgColor
        updateView()
    }

    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        super.didUpdateFocus(in: context, with: coordinator)
        updateView()
    }

    func configure(title: String, systemIcon: String?) {
        titleLabel.text = title
        if let systemIcon {
            let config = UIImage.SymbolConfiguration(pointSize: 28, weight: .medium)
            iconImageView.image = UIImage(systemName: systemIcon, withConfiguration: config)?.withRenderingMode(.alwaysTemplate)
            iconImageView.isHidden = false
        } else {
            iconImageView.image = nil
            iconImageView.isHidden = true
        }
        updateView()
    }

    func updateView() {
        selectedWhiteView.isHidden = !(isFocused || isSelected)
        selectedWhiteView.backgroundColor = isFocused ? .white : UIColor.white.withAlphaComponent(0.22)
        let fg: UIColor = isFocused ? .black : .white
        titleLabel.textColor = fg
        iconImageView.tintColor = fg
    }

    static func makeLayout() -> UICollectionViewLayout {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.9),
                                              heightDimension: .fractionalHeight(1.0))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                               heightDimension: .absolute(64))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize,
                                                       subitems: [item])
        group.edgeSpacing = .init(leading: nil, top: .fixed(6), trailing: nil, bottom: nil)
        let section = NSCollectionLayoutSection(group: group)
        let layout = UICollectionViewCompositionalLayout(section: section)
        return layout
    }
}
