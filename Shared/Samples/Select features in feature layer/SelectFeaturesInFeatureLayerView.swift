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
import ArcGIS

struct SelectFeaturesInFeatureLayerView: View {
    /// The selected features.
    @State private var selectedFeatures: [Feature] = []
    
    /// The point indicating where to identify features.
    @State private var identifyPoint: CGPoint?
    
    /// A Boolean value indicating whether to show an alert.
    @State private var isShowingAlert = false
    
    /// The error shown in the alert.
    @State private var error: Error? {
        didSet { isShowingAlert = error != nil }
    }
    
    /// The view model for the sample.
    @StateObject private var model = Model()
    
    var body: some View {
        MapViewReader { mapViewProxy in
            MapView(map: model.map)
                .onSingleTapGesture { screenPoint, _ in
                    identifyPoint = screenPoint
                }
                .task(id: identifyPoint) {
                    guard let identifyPoint = identifyPoint else { return }
                    
                    do {
                        // Unselects the selected features.
                        model.featureLayer.unselectFeatures(selectedFeatures)
                        
                        // Saves the results from the identify method on the map view proxy.
                        let results = try await mapViewProxy.identify(
                            on: model.featureLayer,
                            screenPoint: identifyPoint,
                            tolerance: 12,
                            maximumResults: 10
                        )
                        
                        // Updates the selected features to the geo elements from the results.
                        selectedFeatures = results.geoElements as! [Feature]
                        
                        // Selects the features from the selected features array.
                        model.featureLayer.selectFeatures(selectedFeatures)
                    } catch {
                        // Updates the error and shows an alert.
                        self.error = error
                    }
                }
                .overlay(alignment: .top) {
                    Text("\(selectedFeatures.count) feature(s) selected.")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(.thinMaterial, ignoresSafeAreaEdges: .horizontal)
                }
                .alert(isPresented: $isShowingAlert, presentingError: error)
        }
    }
}

private extension SelectFeaturesInFeatureLayerView {
    class Model: ObservableObject {
        /// A feature layer visualizing GDP per capita.
        let gdpPerCapitaLayer = FeatureLayer(
            item: PortalItem(
                portal: .arcGISOnline(connection: .anonymous),
                id: .gdpPerCapita
            )
        )

        /// A map with a topographic basemap style and a feature layer.
        let map: Map

        init() {
            map = Map(basemapStyle: .arcGISTopographic)
            map.addOperationalLayer(gdpPerCapitaLayer)
        }
    }
}

private extension PortalItem.ID {
    static var gdpPerCapita: Self { Self("10d76a5b015647279b165f3a64c2524f")! }
}
