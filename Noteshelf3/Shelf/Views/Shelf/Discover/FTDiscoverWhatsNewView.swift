//
//  FTDiscoverView.swift
//  Noteshelf3
//
//  Created by Ramakrishna on 16/08/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import SwiftUI

struct FTDiscoverItemModel: Identifiable {
    var id: UUID = UUID()
    var imageName: String
    var title: String
    var description: String
    var url:URL?
    var eventTrackName: String
}
struct FTDiscoverWhatsNewView: View {
    @AppStorage("discoverIsExpanded") var discoverExpandStaus: Bool = false
    @State var isExpanded: Bool = false

    @EnvironmentObject var sheflViewModel: FTShelfViewModel

    var body: some View {
        VStack(alignment: .leading){
            DisclosureGroup(isExpanded: Binding<Bool>(
                get: { isExpanded},
                set: { isExpanding in
                    isExpanded = isExpanding
                    discoverExpandStaus = isExpanding
                    let eventName = isExpanding ? EventName.discover_expand : EventName.discover_collapse
                    track(eventName, screenName: ScreenName.shelf)
                }
            )) {  ScrollView(.horizontal,showsIndicators: false) {
                    HStack(alignment: .top, spacing:24){
                        ForEach(discoverItemsDatasource){ item in
                            footerView(item: item)
                            .padding(.top, 16)
                            .padding(.bottom, 16)
                            .onTapGesture {
                                track(EventName.discover_blog_tap, params:[EventParameterKey.title:"\(item.eventTrackName)"], screenName: ScreenName.shelf)
                                self.sheflViewModel.delegate?.openDiscoveryItemsURL(item.url)
                            }
                        }
                        .padding(.leading,8)
                    }
                }
            } label: {
                Text("shelf.discover.title".localized)
                    .font(.appFont(for: .bold, with: 15))
                    .padding(.leading,8)
            }
            .padding(.top,16)
            .padding(.horizontal,24)
            .if(!isExpanded, transform: { view in
                view.padding(.bottom,16)
            })
            .accentColor(.appColor(.black1))
        }
        .background(Color.appColor(.black5))
        .cornerRadius(16)
    }
    
    private func footerView(item: FTDiscoverItemModel) -> some View {
        return VStack {
            VStack(spacing: 8) {
                Image(uiImage: UIImage(named: item.imageName)!)
                    .frame(width: 120, height:80)
                Text(item.title.localized)
                    .appFont(for: .medium, with: 13)
            }
        }
        .frame(width: 120)
        
    }
    
    private func discoverableView(item: FTDiscoverItemModel) -> some View {
        return VStack(alignment: .leading,spacing:0){
             Image(uiImage: UIImage(named: item.imageName)!)
                 .resizable()
                 .frame(width: 248,height:165,alignment:.top)
             
             VStack(alignment: .leading,spacing: 2) {
                 Text(item.title.localized)
                     .frame(maxWidth:.infinity,maxHeight:22,alignment:.leading)
                     .foregroundColor(.appColor(.black1))
                     .font(.clearFaceFont(for: .regular, with: 17))
                     .multilineTextAlignment(.leading)
                     .padding(.top,12)
                 
                 Text(item.description.localized)
                     .frame(maxWidth:.infinity, alignment:.leading)
                     .foregroundColor(.appColor(.black70))
                     .font(.appFont(for: .regular, with: 12))
                     .multilineTextAlignment(.leading)
             }
             .padding(.horizontal,12)
             .frame(width: 248,height: 95,alignment: .top)
             .background(Color.appColor(.white100))
         }
         .cornerRadius(4)
         .frame(width: 248,height: 260)
         .padding(.top,16)
         .padding(.trailing,24)
         .padding(.bottom,24)
         .shadow(color: Color.appColor(.black16), radius:4, x: 0, y: 2)
    }
    
    private var discoverItemsDatasource: [FTDiscoverItemModel] {
        return [
            FTDiscoverItemModel(imageName: "whatsNew", title: "shelf.discover.whatsNewTitle", description: "shelf.discover.whatsNewDescription", url: URL(string: "https://medium.com/noteshelf/introducing-all-new-noteshelf-3-3a89f78fd240"), eventTrackName: "What’s new in Noteshelf"),
            FTDiscoverItemModel(imageName: "ns2ToNS3Migration", title: "shelf.discover.migrationTitle", description: "shelf.discover.migrationDescription", url: URL(string: "https://noteshelf-support.fluidtouch.biz/hc/en-us/articles/22064417946777-How-to-migrate-notes-from-Noteshelf-2-to-Noteshelf-3-"), eventTrackName: "Migrate from Noteshelf 2"),
            FTDiscoverItemModel(imageName: "aiAssited", title: "shelf.discover.aiAssitedNotesTitle", description: "shelf.discover.aiAssitedDescription", url: URL(string: "https://medium.com/noteshelf/introducing-noteshelf-ai-beta-b629dea9964b"), eventTrackName: "Ai-assited notes"),
            FTDiscoverItemModel(imageName: "getInspired", title: "shelf.discover.getInspiredTitle", description: "shelf.discover.getInspiredDescription", url: URL(string: "https://d1amf23cmdhalo.cloudfront.net/Get_Inspired.pdf"), eventTrackName: "Get inspired"),
            FTDiscoverItemModel(imageName: "covers", title: "shelf.discover.coversTitle", description: "shelf.discover.coversDescription", url: URL(string: "https://medium.com/noteshelf/covers-that-match-your-style-4eec967cbfa"), eventTrackName: "Covers to match your style"),
            FTDiscoverItemModel(imageName: "templates", title: "shelf.discover.templatesTitle", description: "shelf.discover.templatesDescription", url: URL(string: "https://medium.com/noteshelf/a-template-for-every-need-7292ca51294c"), eventTrackName: "A template for every need"),
            FTDiscoverItemModel(imageName: "digitalDiaries", title: "shelf.discover.digitalDiariesTitle", description: "shelf.discover.digitalDiariesDescription", url: URL(string: "https://medium.com/noteshelf/digital-diaries-planners-and-more-1b0eb291db1c"), eventTrackName: "Digital diaries & planners"),
            FTDiscoverItemModel(imageName: "toolBar", title: "shelf.discover.customToolbarTitle", description: "shelf.discover.customToolbarDescription", url: URL(string: "https://medium.com/noteshelf/customize-your-toolbar-89b3c77bc10c"), eventTrackName: "Customize your toolbar"),
            FTDiscoverItemModel(imageName: "organize", title: "shelf.discover.tagsTitle", description: "shelf.discover.tagsDescription", url: URL(string: "https://medium.com/noteshelf/organize-better-access-faster-952e0b79daf"), eventTrackName: "Organize your notes"),
            FTDiscoverItemModel(imageName: "focusMode", title: "shelf.discover.focusModeTitle", description: "shelf.discover.focusModeDescription", url: URL(string: "https://medium.com/noteshelf/take-focused-notes-anywhere-5a67359ab571"), eventTrackName: "Focus mode")]
    }
}

struct FTDiscoverView_Previews: PreviewProvider {
    static var previews: some View {
        FTDiscoverWhatsNewView()
    }
}
