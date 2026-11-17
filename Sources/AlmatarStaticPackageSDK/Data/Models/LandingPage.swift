//
//  LandingPage.swift
//  AlmatarStaticPackageSDK
//
//  `GET api/v1/user-recommendation/landing-pages`
//

import Foundation

/// A marketing landing page from `GET api/v1/user-recommendation/landing-pages`.
public struct LandingPage: Decodable, Sendable, Hashable, Identifiable {
    public let id: String
    public let slug: String?
    public let title: String?
    public let description: String?
    /// The web / default image.
    public let mainImage: LandingPageMedia?
    /// The mobile image, when the page has one.
    public let mobileImage: LandingPageMedia?
    /// `true` for the page shown as the hero banner.
    public let isHero: Bool
    /// The hero banner media, set only on the hero page.
    public let heroMedia: LandingPageHeroMedia?
    /// The page's `"packages"` sections, ready for `getPackagesListView(section:)`.
    /// Empty in the list response; load the page with `fetchLandingPage(id:)` to get them.
    /// Other section types (hero, search box, FAQ, …) are not decoded.
    public let packagesSections: [PackagesSection]

    /// The image to show on mobile: the mobile image, else the main image.
    public var imageURL: URL? { mobileImage?.mediaURL ?? mainImage?.mediaURL }

    /// The hero banner image to show on mobile: the hero media, else `imageURL`.
    public var heroImageURL: URL? {
        heroMedia?.mobileImage?.mediaURL ?? heroMedia?.webImage?.mediaURL ?? imageURL
    }

    private enum CodingKeys: String, CodingKey {
        case id, slug, title, description, mainImage, mobileImage, isHero, heroMedia, sections
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(FlexibleID.self, forKey: .id).value
        slug = try? container.decodeIfPresent(String.self, forKey: .slug)
        title = try? container.decodeIfPresent(String.self, forKey: .title)
        description = try? container.decodeIfPresent(String.self, forKey: .description)
        mainImage = try? container.decodeIfPresent(LandingPageMedia.self, forKey: .mainImage)
        mobileImage = try? container.decodeIfPresent(LandingPageMedia.self, forKey: .mobileImage)
        isHero = (try? container.decodeIfPresent(Bool.self, forKey: .isHero)) ?? false
        heroMedia = try? container.decodeIfPresent(LandingPageHeroMedia.self, forKey: .heroMedia)
        let sections = (try? container.decodeIfPresent([LandingPageSection].self, forKey: .sections)) ?? []
        packagesSections = sections.compactMap(\.packagesSection)
    }
}

/// One entry of `sections`. Only `"packages"` sections are kept; a package that can't be
/// decoded is skipped instead of dropping its section.
private struct LandingPageSection: Decodable {
    let packagesSection: PackagesSection?

    private enum CodingKeys: String, CodingKey { case type, title, packages }

    private struct PackageEntry: Decodable {
        let package: PackageSummary?
        init(from decoder: Decoder) throws { package = try? PackageSummary(from: decoder) }
    }

    init(from decoder: Decoder) throws {
        guard let container = try? decoder.container(keyedBy: CodingKeys.self),
              let type = try? container.decodeIfPresent(String.self, forKey: .type),
              type == "packages" else {
            packagesSection = nil
            return
        }
        let title = try? container.decodeIfPresent(String.self, forKey: .title)
        let entries = (try? container.decodeIfPresent([PackageEntry].self, forKey: .packages)) ?? []
        packagesSection = PackagesSection(type: type, title: title, packages: entries.compactMap(\.package))
    }
}

/// An image or video attached to a landing page.
public struct LandingPageMedia: Decodable, Sendable, Hashable {
    /// `"image"` or `"video"`.
    public let type: String?
    /// The raw URL as sent by the API. It can contain spaces or other unescaped characters;
    /// use `mediaURL` to load it.
    public let url: String?

    /// `url` as a `URL`, percent-encoding characters such as spaces when needed.
    public var mediaURL: URL? {
        guard let url, !url.isEmpty else { return nil }
        if let parsed = URL(string: url) { return parsed }
        return url.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed).flatMap(URL.init(string:))
    }
}

/// The hero banner media of the hero landing page.
public struct LandingPageHeroMedia: Decodable, Sendable, Hashable {
    public let webImage: LandingPageMedia?
    public let mobileImage: LandingPageMedia?
}

/// `GET api/v1/user-recommendation/landing-pages/{id}` wraps the page in `data`.
struct LandingPageResponse: Decodable {
    let data: LandingPage?
}

/// `GET api/v1/user-recommendation/landing-pages` wraps the list in `data`.
/// A page that can't be decoded is skipped instead of failing the whole list.
struct LandingPagesResponse: Decodable {
    let data: [LandingPage]?

    private enum CodingKeys: String, CodingKey { case data }

    private struct Entry: Decodable {
        let page: LandingPage?
        init(from decoder: Decoder) throws { page = try? LandingPage(from: decoder) }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        data = try container.decodeIfPresent([Entry].self, forKey: .data)?.compactMap(\.page)
    }
}
