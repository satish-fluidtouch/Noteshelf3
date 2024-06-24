//
//  FTToolbarCenterPanelController+TipUI.swift
//  Noteshelf3
//
//  Created by Sameer Hussain on 29/05/24.
//  Copyright © 2024 Fluid Touch Pte Ltd. All rights reserved.
//

import TipKit
import UIKit
import FTCommon

@available (iOS 17.0, *)
struct NewFeatures: Tip{
    var title : Text {
        Text("tipeview.shortcut.title".localized)
            .foregroundStyle(.white)
            
    }
    var message: Text?{
        Text("tipeview.shortcut.message".localized)
            .foregroundStyle(Color(uiColor: UIColor.white.withAlphaComponent(0.7) ))
    }
    
    var image : Image? {
        Image(uiImage: UIImage(named: "desk_tool_bulb") ?? UIImage())
    }
    
}
@available (iOS 17.0, *)
struct CustomTiPView : TipViewStyle {
  @State var size: CGSize = .zero
  func makeBody(configuration: Configuration) -> some View {
    HStack(alignment: .top, spacing: 12) {
      VStack {
        configuration.image?
          .resizable()
          .frame(width: 32, height: 32)
          .aspectRatio(contentMode: .fit)
          .padding(.top,2)
        Spacer()
          .frame(maxHeight: self.size.height)
      }
      VStack(alignment: .leading) {
        configuration.title
              .font(.system(size:17,weight: .bold))
          .fixedSize(horizontal: false, vertical: true)
        configuration.message?
          .font(.subheadline)
          .fixedSize(horizontal: false, vertical: true)
      }
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 12)
    .background(
      GeometryReader { geometry in
        Color.clear
          .onAppear {
            self.size = geometry.size
          }
      })
  }
}

extension FTToolbarCenterPanelController {
    func setUpTipForNewFeatures() {
        if #available(iOS 17.0, *) {
            let newFeautres = NewFeatures()
            Task { @MainActor in
                for await shouldDisplay in newFeautres.shouldDisplayUpdates {
                    if shouldDisplay {
                        let controller = TipUIPopoverViewController(newFeautres, sourceItem: self.collectionView)
                        controller.view.backgroundColor = UIColor.init(hexString: "#474747")
                        controller.viewStyle = CustomTiPView()
                        present(controller, animated: true)
                    } else if presentedViewController is TipUIPopoverViewController {
                        dismiss(animated: true)
                    }
                }
            }
        } else {
            debugPrint("Using Lower versions then Ios 17")
        }
    }
}
