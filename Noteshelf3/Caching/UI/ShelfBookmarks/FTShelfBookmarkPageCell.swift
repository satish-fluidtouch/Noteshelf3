class FTShelfBookmarkPageCell: UICollectionViewCell {
    @IBOutlet weak var thumbnail: UIImageView?
    @IBOutlet weak var bookTitleLbl: UILabel?
    @IBOutlet weak var pageTitleLbl: UILabel?
    @IBOutlet weak private var bookmarkIcon: UIButton?
    @IBOutlet weak var shadowImageView: UIImageView!
    @IBOutlet weak var bookmarkName: UILabel!

    func updateBookmarkItemCellContent(bookmarkItem: FTBookmarksItem) {
        self.shadowImageView.isHidden = false

        self.bookTitleLbl?.text = bookmarkItem.shelfItem.displayTitle
        self.bookmarkName.text = bookmarkItem.bookmarkTitle

        let docUUID = bookmarkItem.documentUUID
        self.pageTitleLbl?.text = String(format: "sidebar.bookmarks.page".localized, String(describing: bookmarkItem.pageIndex + 1))

        self.thumbnail?.backgroundColor = UIColor.lightGray.withAlphaComponent(0.1)
        self.thumbnail?.image = nil
        bookmarkIcon?.tintColor = UIColor(hexString: bookmarkItem.bookmarkColor)

        let image = UIImage(named: "pages_shadow")
        let scalled = image?.resizableImage(withCapInsets: UIEdgeInsets(top: 8, left: 20, bottom: 32, right: 20), resizingMode: .stretch)
        shadowImageView.image = scalled
        self.shadowImageView.layer.cornerRadius = 10
        self.thumbnail?.layer.cornerRadius = 10
        self.thumbnail?.image = UIImage(named: "finder-empty-pdf-page");

        FTBookmarksProvider.shared.thumbnail(documentUUID: docUUID, pageUUID: bookmarkItem.pageUUID) { [weak self] image, pageUUID in
            guard let self = self else { return }
            if let image {
                self.thumbnail?.image = image
            }
        }
    }
}
