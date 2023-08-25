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
}
struct FTDiscoverWhatsNewView: View {

    @State private var isExpanded:Bool = true
    @EnvironmentObject var sheflViewModel: FTShelfViewModel

    var body: some View {
        VStack(alignment: .leading){
            DisclosureGroup(isExpanded: $isExpanded) {
                VStack{
                    ScrollView(.horizontal,showsIndicators: false){
                        HStack(alignment: .top, spacing:0){
                            ForEach(discoverItemsDatasource){ item in
                                VStack(alignment: .leading,spacing:0){
                                    Image(uiImage: UIImage(named: item.imageName)!)
                                        .resizable()
                                        .frame(width: 230,height:165,alignment:.top)
                                    VStack(alignment: .leading,spacing: 2) {
                                        Text(item.title.localized)
                                            .foregroundColor(.appColor(.black1))
                                            .font(.clearFaceFont(for: .regular, with: 17))
                                            .multilineTextAlignment(.leading)
                                            .frame(maxWidth:.infinity,maxHeight:22,alignment:.leading)
                                            .padding(.horizontal,12)
                                            .padding(.top,12)
                                        Text(item.description.localized)
                                            .frame(maxWidth:.infinity, alignment:.leading)
                                            .foregroundColor(.appColor(.black70))
                                            .font(.appFont(for: .regular, with: 12))
                                            .multilineTextAlignment(.leading)
                                            .padding(.horizontal,12)
                                    }
                                    .frame(width: 230,height: 95,alignment: .top)
                                    .background(Color.appColor(.white100))
                                }
                                .cornerRadius(4)
                                .frame(width: 230,height: 260)
                                .padding(.top,16)
                                .padding(.trailing,16)
                                .padding(.bottom,24)
                                .shadow(color: Color.appColor(.black16), radius:4, x: 0, y: 2)
                                .onTapGesture {
                                    self.sheflViewModel.delegate?.openDiscoveryItemsURL(item.url)
                                }
                            }
                        }
                        .padding(.leading,8)
                    }
                }
            } label: {
                Text("shelf.discover.title".localized)
                    .font(.clearFaceFont(for: .medium, with: 22))
                    .padding(.leading,8)
            }
            .padding(.top,24)
            .padding(.trailing,24)
            .padding(.leading,16)
            .if(!isExpanded, transform: { view in
                view.padding(.bottom,24)
            })
            .accentColor(.appColor(.black1))
        }
        .background(Color.appColor(.black5))
        .cornerRadius(16)
    }
    private var discoverItemsDatasource: [FTDiscoverItemModel] {
        return [
            FTDiscoverItemModel(imageName: "whatsNew", title: "shelf.discover.whatsNewTitle", description: "shelf.discover.whatsNewDescription", url: URL(string: "https://medium.com/noteshelf/introducing-all-new-noteshelf-3-3a89f78fd240")),
            FTDiscoverItemModel(imageName: "ns2ToNS3Migration", title: "shelf.discover.migrationTitle", description: "shelf.discover.migrationDescription", url: URL(string: "https://noteshelf-support.fluidtouch.biz/hc/en-us/articles/22064417946777-How-to-migrate-notes-from-Noteshelf-2-to-Noteshelf-3-")),
            FTDiscoverItemModel(imageName: "covers", title: "shelf.discover.coversTitle", description: "shelf.discover.coversDescription", url: URL(string: "https://medium.com/noteshelf/covers-that-match-your-style-4eec967cbfa")),
            FTDiscoverItemModel(imageName: "templates", title: "shelf.discover.templatesTitle", description: "shelf.discover.templatesDescription", url: URL(string: "https://medium.com/noteshelf/a-template-for-every-need-7292ca51294c")),
            FTDiscoverItemModel(imageName: "digitalDiaries", title: "shelf.discover.digitalDiariesTitle", description: "shelf.discover.digitalDiariesDescription", url: URL(string: "https://medium.com/noteshelf/digital-diaries-planners-and-more-1b0eb291db1c")),
            FTDiscoverItemModel(imageName: "toolBar", title: "shelf.discover.customToolbarTitle", description: "shelf.discover.customToolbarDescription", url: URL(string: "https://medium.com/noteshelf/customize-your-toolbar-89b3c77bc10c")),
            FTDiscoverItemModel(imageName: "tags", title: "shelf.discover.tagsTitle", description: "shelf.discover.tagsDescription", url: URL(string: "https://medium.com/noteshelf/organize-better-access-faster-952e0b79daf")),
            FTDiscoverItemModel(imageName: "focusMode", title: "shelf.discover.focusModeTitle", description: "shelf.discover.focusModeDescription", url: URL(string: "https://medium.com/noteshelf/take-focused-notes-anywhere-5a67359ab571"))]
    }
}

struct FTDiscoverView_Previews: PreviewProvider {
    static var previews: some View {
        FTDiscoverWhatsNewView()
    }
}
