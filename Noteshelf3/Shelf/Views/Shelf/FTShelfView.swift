
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
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    let supportedDropTypes = FTDragAndDropHelper.supportedTypesForDrop()
    private var idiom : UIUserInterfaceIdiom { UIDevice.current.userInterfaceIdiom }
    
    var body: some View {
        
        //    debugPrintChanges()
        // let _ = Self._printChanges()
        GeometryReader { geometry in
            ZStack {
                if viewModel.canShowNoItemsView && viewModel.showNoShelfItemsView {
                    emptyShelfItemsView()
                }
                ScrollView(.vertical) {
                    VStack(alignment: .center, spacing:0) {
                        if viewModel.showNewNoteView,
                           geometry.size.width > 300,
                           viewModel.canShowCreateNBButtons {
                            FTShelfTopSectionView()
                                .frame(maxWidth:.infinity,minHeight: showMinHeight(geometrySize: geometry.size.width), maxHeight: .infinity,alignment: .center)
                                .padding(.horizontal,gridHorizontalPadding)
                                .padding(.top,10)
                                .environmentObject(viewModel)

                        }
                        shelfGridView(items: viewModel.shelfItems, size: geometry.size)
                            .padding(.top,20)
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
                .detectOrientation($viewModel.orientation)
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
                .onChange(of: viewModel.reloadShelfItems) { reload in
                    if reload {
                        viewModel.reloadShelf()
                        viewModel.reloadShelfItems = false
                    }
                }
                .onTapGesture {
                    self.hideKeyboard() // if any textfield is in editing state we exit from that mode and perform action. eg.rename category.
                }
                .onDrop(of: supportedDropTypes, delegate: FTShelfScrollViewDropDelegate(viewModel: viewModel))
            }
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
        } else { // isUnfiledNotesShelfItemCollection
            return FTNoResultsView(noResultsImageName: "noUnCategorizedIcon",
                                   title: NSLocalizedString("shelf.starred.noUnfiledTitle", comment: "No unfiled notes"),
                                   description: NSLocalizedString("shelf.starred.noUnfiledDescription", comment: "All notebooks and groups which aren’t in any categories will appear here."))
        }
    }
    
    private func showMinHeight(geometrySize:CGFloat) -> CGFloat{
        let isInPortrait = UIScreen.main.bounds.height > UIScreen.main.bounds.width
        if geometrySize < 600 || (isInPortrait && self.viewModel.isSidebarOpen) {
            return 96
        } else {
            return 68
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
