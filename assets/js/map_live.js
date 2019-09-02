import Leaflet from "leaflet"
import LiveSocket from "phoenix_live_view"
import socket from "./socket"
const pathname = window.location.pathname.slice(0, 5)

if(pathname == "/map_") {

function updateMap() {
  let bounds = map.getBounds()
  let northEast = bounds._northEast
  let southWest = bounds._southWest

  channel.push("location_change", {
    northEastLatitude: northEast.lat,
    northEastLongitude: northEast.lng,
    southWestLatitude: southWest.lng,
    southWestLongitude: southWest.lng,
  })
}

let channel = socket.channel("map:lobby", {})
channel.join()
  .receive("ok", resp => { console.log("Joined successfully", resp) })
  .receive("error", resp => { console.log("Unable to join", resp) })

let map = L.map('live_map').setView([42.9994366888185, -87.8985320066727], 15);

L.tileLayer('https://api.tiles.mapbox.com/v4/{id}/{z}/{x}/{y}.png?access_token=pk.eyJ1IjoibWFwYm94IiwiYSI6ImNpejY4NXVycTA2emYycXBndHRqcmZ3N3gifQ.rJcFIG214AriISLbB6B5aw', {
  maxZoom: 18,
  minZoom: 10,
  attribution: 'Map data &copy; <a href="https://www.openstreetmap.org/">OpenStreetMap</a> contributors, ' +
  '<a href="https://creativecommons.org/licenses/by-sa/2.0/">CC-BY-SA</a>, ' +
  'Imagery © <a href="https://www.mapbox.com/">Mapbox</a>',
  id: 'mapbox.light'
}).addTo(map);

let myRenderer = L.canvas({ padding: 0.5 })
let layerGroup = L.layerGroup()
const layerSelect = document.getElementById("layer-select");
let selectedLayer = layerSelect.value

channel.push("layer_change", {layer: layerSelect.value})
updateMap()

let legend = L.control({position: 'bottomright'});
let legendInfo = {'colors': [], 'labels': []}

layerGroup.addTo(map)

layerSelect.addEventListener('change', (e) => {
  channel.push("layer_change", {layer: e.target.value})
  layerGroup.clearLayers()
  selectedLayer = e.target.value
});

function handleNewShapes(data, shouldUpdateLegend) {
  const newData = data.shapefiles

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

  if(shouldUpdateLegend) {
    updateLegend(data.legend)
  }
}

function updateLegend(newLegendInfo) {
  legendInfo = newLegendInfo;
  map.removeControl(legend);
  legend = L.control({position: 'bottomright'});
  legend.onAdd = function (map) {
    let div = L.DomUtil.create('div', 'info legend')
    const colors = legendInfo.colors
    let labels = legendInfo.labels

    // loop through our density intervals and generate a label with a colored square for each interval
    for (var i = 0; i < labels.length; i++) {
      div.innerHTML +=
        '<i style="background:' + colors[i] + '"></i> ' +
        labels[i] + (labels[i + 1] ? '<br>' : '');
    }

    return div;
  };

  legend.addTo(map);
}

map.on('moveend', (e) => {
  updateMap()
})

channel.on("location_change", payload => {
  handleNewShapes(payload, false)
})
channel.on("layer_change", payload => {
  updateLegend(payload["legend"])
  updateMap()
})
}
