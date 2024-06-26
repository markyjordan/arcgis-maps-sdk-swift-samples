# Navigate route with rerouting

Navigate between two points and dynamically recalculate an alternate route when the original route is unavailable.

![Image of navigate route with rerouting](navigate-route-with-rerouting.png)

## Use case

While traveling between destinations, field workers use navigation to get live directions based on their locations. In cases where a field worker makes a wrong turn, or if the route suggested is blocked due to a road closure, it is necessary to calculate an alternate route to the original destination.

## How to use the sample

Tap the play button to simulate traveling and to receive directions from a preset starting point to a preset destination. Observe how the route is recalculated when the simulation does not follow the suggested route. Tap the recenter button to reposition the viewpoint. Tap the reset button to start the simulation from the beginning.

## How it works

1. Create a `RouteTask` using local network data.
2. Generate default `RouteParameters` using `RouteTask.makeDefaultParameters()`.
3. Set `returnsStops` and `returnsDirections` on the parameters to true.
4. Add `Stop`s to the parameters' `stops` array using `RouteParameters.setStops(_:)`.
5. Solve the route using `RouteTask.solveRoute(using:)` to get a `RouteResult`.
6. Create a `RouteTracker` using the route result and the index of the desired route to take.
7. Enable rerouting on the route tracker with `RouteTracker.enableRerouting(using:)`.
8. Use `RouteTracker.$trackingStatus` to display updated route information and update the route graphics. Tracking status includes a variety of information on the route progress, such as the remaining distance, remaining geometry or traversed geometry (represented by a `Polyline`), or the remaining time (`TimeInterval`), amongst others.
9. You can also query the tracking status for the current `DirectionManeuver` index, retrieve that maneuver from the `Route`, and get its direction text to display.
10. Use `RouteTracker.voiceGuidances` to get the `VoiceGuidance` whenever new instructions are available. From the voice guidance, get the `text` representing the directions and use a text-to-speech engine to output the maneuver directions.
11. To establish whether the destination has been reached, get the `destinationStatus` from the tracking status. If the destination status is `reached`, and the `remainingDestinationCount` is 1, you have arrived at the destination and can stop routing. If there are several destinations in your route, and the remaining destination count is greater than 1, switch the route tracker to the next destination.

## Relevant API

* DestinationStatus
* DirectionManeuver
* Location
* LocationDataSource
* ReroutingStrategy
* Route
* RouteParameters
* RouteTask
* RouteTracker
* Stop
* VoiceGuidance

## Offline data

The [SanDiegoTourPath](https://www.arcgis.com/home/item.html?id=4caec8c55ea2463982f1af7d9611b8d5) JSON file provides a simulated path for the device to demonstrate routing while traveling.

## About the data

The route taken in this sample goes from the San Diego Convention Center, site of the annual Esri User Conference, to the Fleet Science Center, San Diego.

## Additional information

The route tracker will start a rerouting calculation automatically as necessary when the device's location indicates that it is off-route. The route tracker also validates that the device is "on" the transportation network. If it is not (e.g., in a parking lot), rerouting will not occur until the device location indicates that it is back "on" the transportation network.

## Tags

directions, maneuver, navigation, route, turn-by-turn, voice
