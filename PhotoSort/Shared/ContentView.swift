//
//  ContentView.swift
//  Shared
//
//  Created by Dustin Stabinski on 2/20/22.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        let lib = PhotoLibrary();
        Text(lib.photoAuthorization())
            .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
.previewInterfaceOrientation(.portrait)
    }
}
