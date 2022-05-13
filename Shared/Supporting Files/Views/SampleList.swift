// Copyright 2022 Esri
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//   https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import SwiftUI

struct SampleList: View {
    /// A Boolean value that indicates when the user is searching.
    @Environment(\.isSearching) private var isSearching
    /// All samples that will be displayed in the list.
    let samples: [Sample]
    /// The search query in the search bar.
    @Binding var query: String
    
    @State var aboutViewIsPresented = false
    
    /// The samples to display in the list. Searching adjusts this value.
    private var displayedSamples: [Sample] {
        if !isSearching {
            return samples
        } else {
            if query.isEmpty {
                return samples
            } else {
                return samples.filter { $0.name.localizedCaseInsensitiveContains(query) }
            }
        }
    }
    
    var body: some View {
        List(displayedSamples, id: \.name) { sample in
            NavigationLink(sample.name) {
                SampleDetailView(sample: sample)
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    aboutViewIsPresented.toggle()
                } label: {
                    Image(systemName: "info.circle")
                }
                .sheet(isPresented: $aboutViewIsPresented) {
                    AboutView()
                }
            }
        }
    }
}
