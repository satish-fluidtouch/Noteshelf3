//
//  FTGetinspirePDFviewer.swift
//  Noteshelf3
//
//  Created by Rakesh on 19/07/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import SwiftUI
import PDFKit

struct FTGetinspirePDFviewer: View {
    @Binding var selectedPDFURL: String
    @Binding var title: String
    @Environment(\.presentationMode) private var presentationMode
    @State private var isLoading = true

    var body: some View {
        NavigationStack{
            ZStack {
                if let url = URL(string: selectedPDFURL){
                    PDFKitView(url: url.appendingPathExtension("pdf"), isLoading: $isLoading)
                } else {
                    Text("Invalid PDF URL")
                }
                if isLoading{
                    ProgressView()
                }
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(title)
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(icon: .leftArrow)
                            .font(.appFont(for: .regular, with: 17))
                            .foregroundColor(.appColor(.accent))
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("Done".localized)
                            .font(.appFont(for: .regular, with: 17))
                            .foregroundColor(.appColor(.accent))
                    }
                }
            }.macOnlyPlainButtonStyle()
        }
    }
}
struct FTGetinspirePDFviewer_Previews: PreviewProvider {
    static var previews: some View {
        FTGetinspirePDFviewer(selectedPDFURL: .constant(""), title: .constant(""))
    }
}

struct PDFKitView: UIViewRepresentable {
    let url: URL
    @Binding var isLoading: Bool

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
            if let pdfDocument = PDFDocument(url: url) {
                DispatchQueue.main.async {
                    pdfView.document = pdfDocument
                    isLoading = false
                }
            }
        return pdfView
    }
    
    func updateUIView(_ uiView: PDFView, context: Context) {
        uiView.document = PDFDocument(url: url)
    }
}

