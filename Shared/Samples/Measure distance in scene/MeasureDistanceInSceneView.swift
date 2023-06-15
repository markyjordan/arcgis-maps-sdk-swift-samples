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

import SwiftUI
import ArcGIS

struct MeasureDistanceInSceneView: View {
    /// A scene with an imagery basemap.
    @State private var scene = {
        let scene = ArcGIS.Scene(basemapStyle: .arcGISTopographic)
        
        // Add elevation source to the base surface of the scene with the service URL.
        let elevationSource = ArcGISTiledElevationSource(url: .brestElevationService)
        scene.baseSurface.addElevationSource(elevationSource)
        
        // Create the building layer and add it to the scene.
        let buildingsLayer = ArcGISSceneLayer(url: .brestBuildingsService)
        scene.addOperationalLayer(buildingsLayer)
        
        return scene
    }()
    
    /// An analysis overlay for location distance measurement.
    @State private var analysisOverlay = AnalysisOverlay()
    
    /// A string for the direct distance of the location distance measurement.
    @State private var directDistanceText = "--"
    
    /// A string for the horizontal distance of the location distance measurement.
    @State private var horizontalDistanceText = "--"
    
    /// A string for the vertical distance of the location distance measurement.
    @State private var verticalDistanceText = "--"
    
    /// The unit system for the location distance measurement, selected by the picker.
    @State private var unitSystemSelection: UnitSystem = .metric
    
    /// The overlay instruction message text.
    @State private var instructionText: String = .startMessage
    
    /// The location distance measurement.
    private let locationDistanceMeasurement = LocationDistanceMeasurement(
        startLocation: Point(x: -4.494677, y: 48.384472, z: 24.772694, spatialReference: .wgs84),
        endLocation: Point(x: -4.495646, y: 48.384377, z: 58.501115, spatialReference: .wgs84)
    )
    
    /// A measurement formatter for converting the distances to strings.
    private let measurementFormatter: MeasurementFormatter = {
        let measurementFormatter = MeasurementFormatter()
        measurementFormatter.unitOptions = .providedUnit
        measurementFormatter.numberFormatter.minimumFractionDigits = 2
        measurementFormatter.numberFormatter.maximumFractionDigits = 2
        return measurementFormatter
    }()
    
    init() {
        // Set scene the viewpoint specified by the location distance measurement.
        let lookAtPoint = Envelope(
            min: locationDistanceMeasurement.startLocation,
            max: locationDistanceMeasurement.endLocation
        ).center
        let camera = Camera(lookingAt: lookAtPoint, distance: 200, heading: 0, pitch: 45, roll: 0)
        scene.initialViewpoint = Viewpoint(boundingGeometry: lookAtPoint, camera: camera)
        
        // Add location distance measurement to the analysis overlay to display it.
        analysisOverlay.addAnalysis(locationDistanceMeasurement)
    }
    
    var body: some View {
        VStack {
            SceneViewReader { sceneViewProxy in
                SceneView(scene: scene, analysisOverlays: [analysisOverlay])
                    .onSingleTapGesture { screenPoint, _ in
                        // Set the start and end locations when tapped.
                        Task {
                            guard let location = try? await sceneViewProxy.location(
                                fromScreenPoint: screenPoint
                            ) else { return }
                            
                            if locationDistanceMeasurement.startLocation != locationDistanceMeasurement.endLocation {
                                locationDistanceMeasurement.startLocation = location
                                instructionText = .endMessage
                            } else {
                                instructionText = .startMessage
                            }
                            locationDistanceMeasurement.endLocation = location
                        }
                    }
                    .onDragGesture { _, _ in
                        if locationDistanceMeasurement.startLocation == locationDistanceMeasurement.endLocation {
                            return true
                        }
                        return false
                    } onChanged: { screenPoint, _ in
                        // Move the end location on drag.
                        Task {
                            guard let location = try? await sceneViewProxy.location(
                                fromScreenPoint: screenPoint
                            ) else { return }
                            locationDistanceMeasurement.endLocation = location
                        }
                    } onEnded: { _, _ in
                        instructionText = .startMessage
                    }
                    .task {
                        // Set distance text when there is a measurements update.
                        for await measurements in locationDistanceMeasurement.measurements {
                            directDistanceText = measurementFormatter.string(from: measurements.directDistance)
                            horizontalDistanceText = measurementFormatter.string(from: measurements.horizontalDistance)
                            verticalDistanceText = measurementFormatter.string(from: measurements.verticalDistance)
                        }
                    }
                    .overlay(alignment: .top) {
                        // Instruction text.
                        Text(instructionText)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(8)
                            .background(.thinMaterial, ignoresSafeAreaEdges: .horizontal)
                    }
            }
            
            // Distance texts.
            Text("Direct: \(directDistanceText)")
            Text("Horizontal: \(horizontalDistanceText)")
            Text("Vertical: \(verticalDistanceText)")
            
            // Unit system picker.
            Picker("", selection: $unitSystemSelection) {
                Text("Imperial").tag(UnitSystem.imperial)
                Text("Metric").tag(UnitSystem.metric)
            }
            .pickerStyle(.segmented)
            .padding()
            .onChange(of: unitSystemSelection) { _ in
                locationDistanceMeasurement.unitSystem = unitSystemSelection
            }
        }
    }
}

private extension String {
    /// The user instruction message for setting the start location.
    static let startMessage = "Tap on the map to set the start location."
    
    /// The user instruction message for setting the end location.
    static let endMessage = "Tap and drag on the map to set the end location."
}

private extension URL {
    /// A elevation image service URL for Brest, France.
    static var brestElevationService: URL {
        URL(string: "https://scene.arcgis.com/arcgis/rest/services/BREST_DTM_1M/ImageServer")!
    }
    
    /// A scene service URL for buildings in Brest, France.
    static var brestBuildingsService: URL {
        URL(string: "https://tiles.arcgis.com/tiles/P3ePLMYs2RVChkJx/arcgis/rest/services/Buildings_Brest/SceneServer/layers/0")!
    }
}
