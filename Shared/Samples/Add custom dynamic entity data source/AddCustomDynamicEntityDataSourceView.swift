// Copyright 2023 Esri
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

import ArcGIS
import SwiftUI

struct AddCustomDynamicEntityDataSourceView: View {
    /// A map with an ArcGIS oceans basemap style.
    @State var map: Map = {
        let map = Map(basemapStyle: .arcGISOceans)
        map.initialViewpoint = Viewpoint(
            latitude: 47.984,
            longitude: -123.657,
            scale: 3e6
        )
        return map
    }()
    
    /// The dynamic entity layer that is displaying our custom data.
    @State var dynamicEntityLayer: DynamicEntityLayer
    
    /// The point on the screen the user tapped.
    @State private var tappedScreenPoint: CGPoint?
    
    /// The placement of the callout.
    @State private var calloutPlacement: CalloutPlacement?
    
    init() {
        // The meta data for the custom dynamic entity data source.
        let info = DynamicEntityDataSourceInfo(
            entityIDFieldName: "MMSI",
            fields: .vesselFields
        )
        
        info.spatialReference = .wgs84
        
        let customDataSource = CustomDynamicEntityDataSource(info: info) { VesselFeed() }
        
        _dynamicEntityLayer = .init(initialValue: DynamicEntityLayer(dataSource: customDataSource))
        
        let trackDisplayProperties = dynamicEntityLayer.trackDisplayProperties
        trackDisplayProperties.showsPreviousObservations = true
        trackDisplayProperties.showsTrackLine = true
        trackDisplayProperties.maximumObservations = 20
        
        let labelDefinition = LabelDefinition(
            labelExpression: SimpleLabelExpression(simpleExpression: "[VesselName]"),
            textSymbol: TextSymbol(color: .red, size: 12)
        )
        labelDefinition.placement = .pointAboveCenter
        
        dynamicEntityLayer.addLabelDefinition(labelDefinition)
        dynamicEntityLayer.labelsAreEnabled = true
        
        map.addOperationalLayer(dynamicEntityLayer)
    }
    
    var body: some View {
        MapViewReader { proxy in
            MapView(map: map)
                .onSingleTapGesture { screenPoint, _ in
                    tappedScreenPoint = screenPoint
                }
                .callout(placement: $calloutPlacement.animation(.default.speed(2))) { placement in
                    let attributes = (placement.geoElement as! DynamicEntityObservation).attributes
                    VStack(alignment: .leading) {
                        // Display all the attributes in the callout.
                        ForEach(attributes.sorted(by: { $0.key < $1.key }), id: \.key) { item in
                            Text("\(item.key): \(String(describing: item.value))")
                        }
                    }
                }
                .task(id: tappedScreenPoint) {
                    guard let tappedScreenPoint,
                          let identifyResult = try? await proxy.identify(
                            on: dynamicEntityLayer,
                            screenPoint: tappedScreenPoint,
                            tolerance: 2
                          ) else {
                        // Hides the callout.
                        calloutPlacement = nil
                        
                        return
                    }
                    
                    // Set the callout placement to the observation that was tapped on.
                    calloutPlacement = identifyResult.geoElements.first.map { .geoElement($0) }
                }
        }
    }
}

/// The vessel feed that is emitting custom dynamic entity events.
private struct VesselFeed: CustomDynamicEntityFeed {
    let events: AsyncThrowingStream<CustomDynamicEntityFeedEvent, Error> = .init { continuation in
        Task.detached {
            do {
                let fileHandle = try FileHandle(forReadingFrom: .selectedVesselsDataSource)
                let decoder = JSONDecoder()
                
                // Loop through each line in the JSON file.
                for try await line in fileHandle.bytes.lines {
                    // Delay observations to simulate live data.
                    try await Task.sleep(nanoseconds: 10_000_000)
                    
                    let decodable = try decoder.decode(
                        AddCustomDynamicEntityDataSourceView.Vessel.self,
                        from: line.data(using: .utf8)!
                    )
                    
                    // The geometry that was decoded from the JSON.
                    let geometry = decodable.geometry
                    
                    // We successfully decoded the vessel JSON so we should
                    // add that vessel as a new observation.
                    continuation.yield(.newObservation(
                        geometry: Point(x: geometry.x, y: geometry.y, spatialReference: .wgs84),
                        attributes: decodable.attributes
                    ))
                }
                
                continuation.finish()
            } catch {
                continuation.finish(throwing: error)
            }
        }
    }
}

private extension Array<Field> {
    /// An array of fields that match the attributes of each observation in the data source.
    ///
    /// This schema is derived from the first row in the custom data source.
    static var vesselFields: Self {
        return [
            Field(type: .text, name: "MMSI", alias: "MMSI", length: 256),
            Field(type: .float64, name: "SOG", alias: "SOG", length: 8),
            Field(type: .float64, name: "COG", alias: "COG", length: 8),
            Field(type: .text, name: "VesselName", alias: "VesselName", length: 256),
            Field(type: .text, name: "CallSign", alias: "CallSign", length: 256)
        ]
    }
}

private extension URL {
    /// The URL to the selected vessels JSON data.
    static var selectedVesselsDataSource: URL {
        Bundle.main.url(
            forResource: "AIS_MarineCadastre_SelectedVessels_CustomDataSource",
            withExtension: "jsonl"
        )!
    }
}
