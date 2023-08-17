import UIKit
#if targetEnvironment(macCatalyst)
@objc protocol FTMenuActionResponder: NSObjectProtocol {
    //sory by options
    @objc optional func sortByCreatedDate(_ sender: AnyObject?);
    @objc optional func sortByName(_ sender: AnyObject?);
    @objc optional func sortByModifiedDate(_ sender: AnyObject?);
    @objc optional func sortByLastOpenedDate(_ sender: AnyObject?);
    @objc optional func sortByManual(_ sender: AnyObject?);
    
    //view options
    @objc optional func viewAsGallery(_ sender: AnyObject?);
    @objc optional func viewAsIcon(_ sender: AnyObject?);
    @objc optional func viewAsList(_ sender: AnyObject?);
    
    //Zoom options
    @objc optional func zoomInClicked(_ sender: AnyObject?);
    @objc optional func zoomOutClicked(_ sender: AnyObject?);
    @objc optional func actualSizeClicked(_ sender: AnyObject?);
    
    //Add Book Options
    @objc optional func newPageClicked(_ sender: AnyObject?);
    @objc optional func pageFromTemplateClicked(_ sender: AnyObject?);
    @objc optional func importDocumentFromFinderClicked(_ sender: AnyObject?);
    
    @objc optional func audioClicked(_ sender: AnyObject?);
    @objc optional func insertWebClip(_ sender: AnyObject?);
    @objc optional func importMedia(_ sender: AnyObject?);
    
    @objc optional func bookmarkClicked(_ sender: AnyObject?);

    @objc optional func navigateToFirstPage(_ sender: AnyObject?);
    @objc optional func navigateToPreviousPage(_ sender: AnyObject?);
    @objc optional func navigateToLastPage(_ sender: AnyObject?);
    @objc optional func navigateToNextPage(_ sender: AnyObject?);
    
    @objc optional func showShelfScreen(_ sender: AnyObject?);
    @objc optional func createNewNotebook(_ sender: AnyObject?);
    @objc optional func quickCreate(_ sender: AnyObject?);
}

class FTMenuController :  NSObject {
    
    static func buildAppMenu(builder: UIMenuBuilder) {
        builder.remove(menu: .format);
        
        builder.insertSibling(FTZoomOptionsMenu.menu, afterMenu: .toolbar)
        builder.insertSibling(FTSortOptionsMenu.menu, afterMenu: .toolbar)
        builder.insertSibling(FTViewOptionsMenu.menu, afterMenu: .toolbar)
        // Create and add "Open" menu command at the beginning of the File menu.
        builder.insertSibling(FTAddNotebookOptionsMenu.menu, beforeMenu: .window)
        builder.insertSibling(FTNavigationMenu.menu, beforeMenu: .window)
        
        builder.replaceChildren(ofMenu:.file,from: { _ in
            return FTFileNotbookCreationMenu.menu(builder:builder).children;
        });
    }
}

private class FTNavigationMenu: NSObject {
    static var menu: UIMenu {
        let nextPageCommand = UIKeyCommand(title: NSLocalizedString("ShowNextPage", comment: ""),
                                           image: nil,
                                           action: #selector(FTMenuActionResponder.navigateToNextPage(_:)),
                                           input: UIKeyCommand.inputRightArrow,
                                           modifierFlags: [.command],
                                           propertyList: nil)
        let lastPageCommand = UIKeyCommand(title: NSLocalizedString("ShowLastPage", comment: ""),
                                           image: nil,
                                           action: #selector(FTMenuActionResponder.navigateToLastPage(_:)),
                                           input: UIKeyCommand.inputRightArrow,
                                           modifierFlags: [.command, .shift],
                                           propertyList: nil)
        let prevPageCommand = UIKeyCommand(title: NSLocalizedString("ShowPrevPage", comment: ""),
                                           image: nil,
                                           action: #selector(FTMenuActionResponder.navigateToPreviousPage(_:)),
                                           input: UIKeyCommand.inputLeftArrow,
                                           modifierFlags: [.command],
                                           propertyList: nil)
        
        let firstPageCommand = UIKeyCommand(title: NSLocalizedString("ShowFirstPage", comment: ""),
                                            image: nil,
                                            action: #selector(FTMenuActionResponder.navigateToFirstPage(_:)),
                                            input: UIKeyCommand.inputLeftArrow,
                                            modifierFlags: [.command, .shift],
                                            propertyList: nil)
        
        return UIMenu(title: NSLocalizedString("NavigationTitle", comment: ""),
                      identifier: UIMenu.Identifier("com.fluidtouch.noteshelf.menus.navigation"),
                      children: [firstPageCommand,lastPageCommand,nextPageCommand,prevPageCommand])
    }
}

private extension UICommand {
    static func command(titleKey : String,action : Selector) -> UICommand
    {
        let command = UICommand.init(title: NSLocalizedString(titleKey, comment: ""), action: action);
        return command;
    }
}

private class FTZoomOptionsMenu: NSObject {
    static var menu: UIMenu {
        // Create New Date menu key command.
        let zoomInCommand = UIKeyCommand(title: NSLocalizedString("ZoomIn", comment: "Zoom In"),
                                         image: nil,
                                         action: #selector(FTMenuActionResponder.zoomInClicked(_:)),
                                         input: "+",
                                         modifierFlags: [.command],
                                         propertyList: nil)
        
        let zoomOutCommand = UIKeyCommand(title: NSLocalizedString("ZoomOut", comment: "Zoom Out"),
                                          image: nil,
                                          action: #selector(FTMenuActionResponder.zoomOutClicked(_:)),
                                          input: "-",
                                          modifierFlags: [.command],
                                          propertyList: nil)
        
        let actualSizeCommand = UIKeyCommand(title: NSLocalizedString("ActualSize", comment: "Actual Size"),
                                             image: nil,
                                             action: #selector(FTMenuActionResponder.actualSizeClicked(_:)),
                                             input: "0",
                                             modifierFlags: [.command],
                                             propertyList: nil)
        
        // Return the "New" hierarchical menu.
        return UIMenu(title: NSLocalizedString("Zoom", comment: "Zoom"),
                      image: nil,
                      identifier: UIMenu.Identifier("com.fluidtouch.noteshelf.menus.zoomMenu"),
                      options: [.displayInline],
                      children: [zoomInCommand,zoomOutCommand,actualSizeCommand])
    }
}

private class FTSortOptionsMenu: NSObject {
    static var menu: UIMenu {
        var menuItems = [UIKeyCommand]();
        
        FTShelfSortOrder.supportedSortOptions().forEach { eachOrder in
            menuItems.append(eachOrder.menuItem);
        }
        // Return the "New" hierarchical menu.
        return UIMenu(title: NSLocalizedString("Sort", comment: ""),
                      image: nil,
                      identifier: UIMenu.Identifier("com.fluidtouch.noteshelf.menus.sortByMenu"),
                      children: menuItems)
    }
}

private class FTViewOptionsMenu: NSObject {
    static var menu: UIMenu {
        var menuItems = [UIKeyCommand]();
        FTShelfDisplayStyle.supportedStyles.forEach { eachStyle in
            menuItems.append(eachStyle.menuItem);
        }
        
        return UIMenu(title: NSLocalizedString("ViewOptions", comment: ""),
                      image: nil,
                      identifier: UIMenu.Identifier("com.fluidtouch.noteshelf.menus.viewBy"),
                      options: [.displayInline],
                      children: menuItems)
    }
}

private class FTAddNotebookOptionsMenu: NSObject {
    static var menu: UIMenu {
        
        let openMenu =
        UIMenu(title: NSLocalizedString("Insert", comment: ""),
               image: nil,
               identifier: UIMenu.Identifier("com.fluidtouch.noteshelf.menus.addToNotebookMenu"),
               options: [],
               children: [addPageOptions
                          ,addMediaOptions])
        
        return openMenu
    }
    
    private static var addPageOptions: UIMenu {
        let newPageMenuItem = UIKeyCommand(title: AddMenuItemKey.Page.localizedTitle,
                                           image: nil,
                                           action: #selector(FTMenuActionResponder.newPageClicked(_:)),
                                           input: "P",
                                           modifierFlags: [.command,.shift],
                                           propertyList: nil)
        
        let pageTemplateMenuItem = UIKeyCommand(title: AddMenuItemKey.PageFromTemplate.localizedTitle,
                                                image: nil,
                                                action: #selector(FTMenuActionResponder.pageFromTemplateClicked(_:)),
                                                input: "P",
                                                modifierFlags: [.command,.alternate],
                                                propertyList: nil)
        
        let importMenuItem = UIKeyCommand(title: AddMenuItemKey.ImportDocument.localizedTitle,
                                          image: nil,
                                          action: #selector(FTMenuActionResponder.importDocumentFromFinderClicked(_:)),
                                          input: "I",
                                          modifierFlags: [.command,.shift],
                                          propertyList: nil)
        
        let pageOptions = UIMenu(options:[.displayInline],children:[newPageMenuItem
                                                                    ,pageTemplateMenuItem
                                                                    ,importMenuItem]);
        return pageOptions;
    }
    
    private static var addMediaOptions: UIMenu {
        let audioMenuItem = UIKeyCommand(title: AddMenuItemKey.Audio.localizedTitle,
                                         image: nil,
                                         action: #selector(FTMenuActionResponder.audioClicked(_:)),
                                         input: "R",
                                         modifierFlags: [.command,.shift],
                                         propertyList: nil)
                
        let importMediaItem = UICommand(title: AddMenuItemKey.InsertFrom.localizedTitle
                                        , action: #selector(FTMenuActionResponder.importMedia(_:)));
        
        let webClip = UICommand(title: "WebClip"
                                     , action: #selector(FTMenuActionResponder.insertWebClip(_:)));

        let addOptions = UIMenu(options:[.displayInline],children:[audioMenuItem
                                                                   ,importMediaItem
                                                                   ,webClip]);
    
        return addOptions;
    }
}

private class FTFileNotbookCreationMenu: NSObject{
    static func menu(builder: UIMenuBuilder) -> UIMenu {
        let openShelf = UICommand(title: "Open Shelf", action: #selector(FTMenuActionResponder.showShelfScreen(_:)));
        let openShelfMenu = UIMenu(title:"", options: .displayInline , children: [openShelf]);

        let newNotebook = UIKeyCommand(title: "New Notebook",
                                       image: nil,
                                       action: #selector(FTMenuActionResponder.createNewNotebook(_:)),
                                       input: "N",
                                       modifierFlags: [.command],
                                       propertyList: nil)
        let quickNote = UIKeyCommand(title: "Quick Note",
                                       image: nil,
                                       action: #selector(FTMenuActionResponder.quickCreate(_:)),
                                       input: "N",
                                     modifierFlags: [.command,.alternate],
                                       propertyList: nil)

        let notebookCreationOptions = UIMenu(title:"", options: .displayInline , children: [newNotebook,quickNote]);

        var menuItems = [openShelfMenu,notebookCreationOptions];
        if let recentMenu = builder.menu(for: .openRecent) {
            builder.remove(menu: .openRecent);
            menuItems.insert(recentMenu, at: 1)
        }
        else {
        }
        let newNotebookOptions = UIMenu(title: "",children: menuItems);
        return newNotebookOptions;

    }
}
#endif
