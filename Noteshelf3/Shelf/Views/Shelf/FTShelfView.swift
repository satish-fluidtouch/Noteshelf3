
// FTShelfView.swift
// Noteshelf3
//
// Created by Ramakrishna on 12/05/22.
//
import FTStyles
import SwiftUI

enum FTShelfMode {
  case normal
  case selection
}
protocol FTShelfViewDelegate: AnyObject {
  func didTapOnShelfItem(_ item: FTShelfItemProtocol)
}

struct FTShelfView: View,FTShelfBaseView {

    @EnvironmentObject var viewModel: FTShelfViewModel

    let supportedDropTypes = FTDragAndDropHelper.supportedTypesForDrop()
    private var idiom : UIUserInterfaceIdiom { UIDevice.current.userInterfaceIdiom }

    var body: some View {
        
        //         let _ = Self._printChanges()
        GeometryReader { geometry in
            ZStack {
                ScrollViewReader { proxy in
                    ScrollView(.vertical) {
                        VStack(alignment: .center, spacing:0) {
                            if viewModel.showNewNoteView , geometry.size.width > 450, viewModel.mode == .normal, FTFeatureConfigHelper.shared.isFeatureEnabled(.NotebookCreation) {
                                FTShelfTopSectionView()
                                    .frame(height: showMinHeight(geometrySize: geometry.size.width),alignment: .center)
                                    .padding(.horizontal,gridHorizontalPadding)
                                    .padding(.top,10)
                                    .environmentObject(viewModel)
                            }
                            if viewModel.showNoShelfItemsView {
                                emptyShelfItemsView()
                                    .frame(maxWidth: .infinity)
                            }
                            else {
                                shelfGridView(items: viewModel.shelfItems, size: geometry.size, scrollViewProxy: proxy)
                                    .padding(.top,20)
                            }
                        }
                        .frame(minHeight: viewModel.showNoShelfItemsView ? geometry.size.height : nil)
                    }
                }
                .overlay(content: {
                    if viewModel.showDropOverlayView {
                        withAnimation {
                            FTDropOverlayView()
                                .environmentObject(viewModel)
                        }
                    }
                })
                .navigationTitle(viewModel.navigationTitle)
                .allowsHitTesting(viewModel.allowHitTesting)
#if targetEnvironment(macCatalyst)
                .navigationBarBackButtonHidden(true)
#else
                .navigationBarBackButtonHidden(viewModel.mode == .selection)
#endif
                .if(!viewModel.collection.isTrash, transform: { view in
                    view.shelfNavBarItems()
                        .environmentObject(viewModel)
                })
                .if(viewModel.collection.isTrash, transform: { view in
                    view.trashNavBarItems()
                        .environmentObject(viewModel)
                })
                .shelfBottomToolbar()
                .environmentObject(viewModel.toolbarViewModel)
                .environmentObject(viewModel)
                .onTapGesture {
                    self.hideKeyboard() // if any textfield is in editing state we exit from that mode and perform action. eg.rename category.
                }
                .onDrop(of: supportedDropTypes, delegate: FTShelfScrollViewDropDelegate(viewModel: viewModel))
            }
            .overlay(alignment: .bottom, content: {
                FTAdBannerView()
                    .padding(.bottom,8)
            })
        }
    }

    //MARK: Views
    private func emptyShelfItemsView() -> some View {
        if viewModel.collection.isTrash {
            return FTNoResultsView(noResultsImageName: "noTrashItems",
                                   title: NSLocalizedString("shelf.trash.noTrashTitle", comment: "shelf.trash.noTrashTitle"),
                                   description: NSLocalizedString("shelf.trash.noTrashDescrption", comment: "Deleted notes will remain here for 30 days."))
        } else if viewModel.collection.isStarred{
            return FTNoResultsView(noResultsImageName: "noFavoritesIcon",
                                   title: NSLocalizedString("shelf.starred.noStarredTitle", comment: "No starred notes"),
                                   description: NSLocalizedString("shelf.starred.noStarredDescription", comment: "Star your important notes to access them all in one place"))
        } else if viewModel.collection.isUnfiledNotesShelfItemCollection {
            let title = self.viewModel.groupItem == nil ? NSLocalizedString("shelf.starred.noUnfiledTitle", comment: "No unfiled notes") :NSLocalizedString("shelf.group.noGroupItemsTitle", comment: "This group is empty")
            let description = self.viewModel.groupItem == nil ? NSLocalizedString("shelf.starred.noUnfiledDescription", comment: "All notebooks and groups which aren’t in any categories will appear here.") : NSLocalizedString("shelf.category.noCategoryItemsDescription", comment: "Tap on the options above to create new notes or move existing ones.")
            let imageName = self.viewModel.groupItem == nil ? "noUnCategorizedIcon" : "noCategoryItems"
            return FTNoResultsView(noResultsImageName: imageName,
                                   title: title,
                                   description: description)
        } else {
            let title = self.viewModel.groupItem == nil ? NSLocalizedString("shelf.category.noCategoryItemsTitle", comment: "This category is empty") :NSLocalizedString("shelf.group.noGroupItemsTitle", comment: "This group is empty")
            return FTNoResultsView(noResultsImageName: "noCategoryItems",
                                   title: title,
                                   description: NSLocalizedString("shelf.category.noCategoryItemsDescription", comment: "Tap on the options above to create new notes or move existing ones."))
        }
    }
}

struct TransparentBackground: UIViewRepresentable {
  func makeUIView(context: Context) -> UIView {
    let view = UIView()
    DispatchQueue.main.async {
      view.superview?.superview?.backgroundColor = UIColor(hexString: "#000000", alpha: 0.5)
    }
    return view
  }
  func updateUIView(_ uiView: UIView, context: Context) {}
}

class AppState: ObservableObject {
  @Published var sizeClass: UserInterfaceSizeClass = .regular
  init(sizeClass: UserInterfaceSizeClass){
    self.sizeClass = sizeClass
  }
}
