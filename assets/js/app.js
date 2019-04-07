// We need to import the CSS so that webpack will load it.
// The MiniCssExtractPlugin is used to separate it out into
// its own CSS file.
import css from "../css/app.css"

// webpack automatically bundles all modules in your
// entry points. Those entry points can be configured
// in "webpack.config.js".
//
// Import dependencies
//
import "phoenix_html"

import LiveSocket from "phoenix_live_view"
import Leaflet from "leaflet"

let liveSocket = new LiveSocket("/live")
liveSocket.connect()

let map = L.map('map').setView([42.9994366888185, -87.8985320066727], 15);

L.tileLayer('https://api.tiles.mapbox.com/v4/{id}/{z}/{x}/{y}.png?access_token=pk.eyJ1IjoibWFwYm94IiwiYSI6ImNpejY4NXVycTA2emYycXBndHRqcmZ3N3gifQ.rJcFIG214AriISLbB6B5aw', {
  maxZoom: 18,
  attribution: 'Map data &copy; <a href="https://www.openstreetmap.org/">OpenStreetMap</a> contributors, ' +
  '<a href="https://creativecommons.org/licenses/by-sa/2.0/">CC-BY-SA</a>, ' +
  'Imagery © <a href="https://www.mapbox.com/">Mapbox</a>',
  id: 'mapbox.light'
}).addTo(map);

let myRenderer = L.canvas({ padding: 0.5 })
let layerGroup = L.layerGroup()
let taxKeySet = new Set([])
const zoningSelect = document.getElementById("zoning-select");
let selectedZoning = "RT4"
layerGroup.addTo(map)

zoningSelect.addEventListener('change', (e) => {
  taxKeySet = new Set([])
  layerGroup.clearLayers()
  selectedZoning = e.target.value
  updateMap()
});


function updateMap() {
  let bounds = map.getBounds()
  let northEast = bounds._northEast
  let southWest = bounds._southWest

  fetch(`/geojson?northEastLatitude=${northEast.lat}&northEastLongitude=${northEast.lng}&southWestLatitude=${southWest.lat}&southWestLongitude=${southWest.lng}&zoning=${selectedZoning}`)
    .then(response => response.json())
    .then(data => {
      const newData = data.reduce((accumulator, shape) => {
        if(taxKeySet.has(shape.properties.tax_key)) {
          return accumulator
        } else {
          taxKeySet.add(shape.properties.tax_key)
          accumulator.push(shape)
          return accumulator
        }
      }, [])
      L.geoJSON(newData, {renderer: myRenderer, onEachFeature: function(feature, layer) {
        let popupContent = ""

        if (feature.properties && feature.properties.popupContent) {
          popupContent += feature.properties.popupContent
        }

        layer.bindPopup(popupContent)
      },
      style: function (feature) {
        return feature.properties.style;
    }
    }).addTo(layerGroup)
  })
}

map.on('moveend', (e) => {
  updateMap()
})

updateMap()

// Import local files
//
// Local files can be imported directly using relative paths, for example:
// import socket from "./socket"
