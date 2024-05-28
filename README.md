# flutter_live_flights

A new Flutter project.

## How it works
1. Set up mapbox for both iOs and android.
2. makes an HTTP GET request to the OpenSky API
3. extracts the longitude and latitude from the API response and updates the state, periodically.
4. Mark eack lat-long in mapbox using Point annotation manager.


