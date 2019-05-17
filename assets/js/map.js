import Leaflet from "leaflet"
const pathname = window.location.pathname.slice(0, 5)

if(pathname == "/map" || pathname == "/map?") {
let map = L.map('map').setView([42.9994366888185, -87.8985320066727], 15);

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
let taxKeySet = new Set([])
let GIDSet = new Set([])
const layerSelect = document.getElementById("layer-select");
let selectedLayer = layerSelect.value

let legend = L.control({position: 'bottomright'});
let legendInfo = {'colors': [], 'labels': []}

layerGroup.addTo(map)

layerSelect.addEventListener('change', (e) => {
  taxKeySet = new Set([])
  GIDSet = new Set([])
  layerGroup.clearLayers()
  selectedLayer = e.target.value
  updateMap(true)
});

function handleLeadServiceLineData(data, shouldUpdateLegend) {
  const newData = data.shapefiles.reduce((accumulator, shape) => {
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

  if(shouldUpdateLegend) {
    updateLegend(data.legend)
  }
}

function handleBikeLaneData(data, shouldUpdateLegend) {
  const newData = data.shapefiles.reduce((accumulator, shape) => {
    if(GIDSet.has(shape.properties.type + shape.properties.gid)) {
      return accumulator
    } else {
      GIDSet.add(shape.properties.type + shape.properties.gid)
      accumulator.push(shape)
      return accumulator
    }
  }, [])
  L.geoJSON(newData, {renderer: myRenderer,
    style: function (feature) {
      return feature.properties.style;
    }
  }).addTo(layerGroup)

  if(shouldUpdateLegend) {
    updateLegend(data.legend)
  }
}


function updateMap(shouldUpdateLegend) {
  let bounds = map.getBounds()
  let northEast = bounds._northEast
  let southWest = bounds._southWest

  fetch(`/api/geojson?northEastLatitude=${northEast.lat}&northEastLongitude=${northEast.lng}&southWestLatitude=${southWest.lat}&southWestLongitude=${southWest.lng}&layer=${selectedLayer}`)
    .then(response => response.json())
    .then(data => {
      if(selectedLayer === "bike_lanes") {
        handleBikeLaneData(data, shouldUpdateLegend)
      } else {
        handleLeadServiceLineData(data, shouldUpdateLegend)
      }
  })
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

updateMap(true)
}
