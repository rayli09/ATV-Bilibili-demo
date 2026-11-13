//
//  PlayInfoResolver.swift
//  BilibiliLive
//
//  Created by OpenAI on 2026/4/6.
//

import Foundation

enum PlayInfoResolver {
    static func resolve(_ playInfo: PlayInfo) async throws -> PlayInfo {
        if playInfo.isBangumi {
            return try await resolveBangumi(playInfo)
        }
        guard !playInfo.isCidVaild else { return playInfo }
        guard playInfo.aid > 0 else {
            throw ValidationError.argumentInvalid(message: "缺少视频 aid，无法解析播放信息")
        }
        var resolved = playInfo
        let detail = try await WebRequest.requestDetailVideo(aid: playInfo.aid)
        if let redirect = detail.View.redirect_url?.lastPathComponent,
           redirect.starts(with: "ep"), let epid = Int(redirect.dropFirst(2)), epid > 0
        {
            resolved.epid = epid
            return try await resolveBangumi(resolved)
        }
        let info = try? await WebRequest.requestPlayerInfo(aid: playInfo.aid, cid: detail.View.cid)
        resolved.cid = (info?.last_play_cid ?? 0) > 0 ? info?.last_play_cid : detail.View.cid
        if let info, info.last_play_cid == resolved.cid {
            resolved.lastPlayCid = info.last_play_cid
            resolved.playTimeInSecond = info.playTimeInSecond
        }
        return resolved
    }

    private static func resolveBangumi(_ playInfo: PlayInfo) async throws -> PlayInfo {
        var resolved = playInfo
        let info: BangumiInfo
        if let epid = playInfo.epid, epid > 0 {
            info = try await WebRequest.requestBangumiInfo(epid: epid)
        } else if let seasonId = playInfo.seasonId, seasonId > 0 {
            info = try await WebRequest.requestBangumiInfo(seasonID: seasonId)
        } else if playInfo.aid > 0 {
            if !playInfo.isCidVaild {
                resolved.cid = try await WebRequest.requestCid(aid: playInfo.aid)
            }
            return resolved
        } else {
            throw ValidationError.argumentInvalid(message: "缺少番剧标识，无法解析播放信息")
        }

        resolved.seasonId = info.season_id
        resolved.subType = resolved.subType ?? info.type

        let matchedEpisode: BangumiInfo.Episode?
        if let epid = resolved.epid, epid > 0 {
            matchedEpisode = info.findEpisodeById(epid) ?? info.episodes.first ?? info.section?.first?.episodes.first
        } else {
            let lastEpisodeID = info.user_status?.progress?.last_ep_id ?? 0
            matchedEpisode = info.findEpisodeById(lastEpisodeID) ?? info.episodes.first ?? info.section?.first?.episodes.first
        }

        if let episode = matchedEpisode {
            resolved.epid = episode.id
            resolved.aid = episode.aid
            resolved.cid = episode.cid
            if let progress = info.user_status?.progress, progress.last_ep_id == episode.id {
                resolved.lastPlayCid = episode.cid
                resolved.playTimeInSecond = progress.last_time
            }
            if resolved.coverURL == nil {
                resolved.coverURL = episode.cover
            }
            if resolved.title?.isEmpty != false {
                let combinedTitle = [episode.title, episode.long_title]
                    .filter { !$0.isEmpty }
                    .joined(separator: " ")
                resolved.title = combinedTitle.isEmpty ? resolved.title : combinedTitle
            }
        } else {
            throw ValidationError.argumentInvalid(message: "无法找到可播放的番剧选集")
        }

        return resolved
    }
}
