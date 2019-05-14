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
const zoningSelect = document.getElementById("zoning-select");
let selectedZoning = ""

const layerSelect = document.getElementById("layer-select");
let selectedLayer = layerSelect.value

layerGroup.addTo(map)

zoningSelect.addEventListener('change', (e) => {
  taxKeySet = new Set([])
  GIDSet = new Set([])
  layerGroup.clearLayers()
  selectedZoning = e.target.value
  updateMap()
});

layerSelect.addEventListener('change', (e) => {
  taxKeySet = new Set([])
  GIDSet = new Set([])
  layerGroup.clearLayers()
  selectedLayer = e.target.value
  updateMap()
});


var legend = L.control({position: 'bottomright'});

legend.onAdd = function (map) {

  let div = L.DomUtil.create('div', 'info legend')
  const grades = ["#003F5C", "#2F4B7C", "#665191", "#A05195", "#D45087", "#F95D6A", "#FF7C43", "#FFA600", "#FF0000"]
  let colors = []
  let labels = []

    // loop through our density intervals and generate a label with a colored square for each interval
    for (var i = 0; i < grades.length; i++) {
        div.innerHTML +=
            '<i style="background:' + grades[i] + '"></i>'
    }

    return div;
};

// legend.addTo(map);

function handleLeadServiceLineData(data) {
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
}

function handleBikeLaneData(data) {
  const newData = data.reduce((accumulator, shape) => {
    if(GIDSet.has(shape.properties.gid)) {
      return accumulator
    } else {
      GIDSet.add(shape.properties.gid)
      accumulator.push(shape)
      return accumulator
    }
  }, [])
  L.geoJSON(newData, {renderer: myRenderer,
    style: function (feature) {
      return feature.properties.style;
    }
  }).addTo(layerGroup)
}


function updateMap() {
  let bounds = map.getBounds()
  let northEast = bounds._northEast
  let southWest = bounds._southWest

  fetch(`/api/geojson?northEastLatitude=${northEast.lat}&northEastLongitude=${northEast.lng}&southWestLatitude=${southWest.lat}&southWestLongitude=${southWest.lng}&zoning=${selectedZoning}&layer=${selectedLayer}`)
    .then(response => response.json())
    .then(data => {
      if(selectedLayer === "bike_lanes") {
        handleBikeLaneData(data)
      } else {
        handleLeadServiceLineData(data)
      }
  })
}

map.on('moveend', (e) => {
  updateMap()
})

updateMap()

}
