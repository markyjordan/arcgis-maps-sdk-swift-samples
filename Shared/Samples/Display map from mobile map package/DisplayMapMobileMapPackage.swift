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

struct DisplayMapMobileMapPackage: View {
    /// A map with imagery basemap.
    @StateObject private var map = makeMap()
    
    /// Creates a map.
    private static func makeMap() -> Map {
        let featureLayer = FeatureLayer(
            item: PortalItem(
                portal: .arcGISOnline(isLoginRequired: false),
                id: .northAmericaTouristAttractions
            )
        )
        let map = Map(basemapStyle: .arcGISTopographic)
        map.addOperationalLayer(featureLayer)
        return map
    }
    
    var body: some View {
        // Creates a map view to display the map.
        MapView(map: map)
    }
}
