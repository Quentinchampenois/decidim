((exports) => {
  exports.Decidim = exports.Decidim || {};

  const MapController = exports.Decidim.MapController;

  class MapMarkersController extends MapController {
    start() {
      this.markerClusters = null;

      if (Array.isArray(this.config.markers) && this.config.markers.length > 0) {
        this.addMarkers(this.config.markers);
      } else {
        this.map.fitWorld();
      }
    }

    reverseGeocoding(element, coord) {
      $.ajax({
        method: "GET",
        url: "https://reverse.geocoder.ls.hereapi.com/6.2/reversegeocode.json",
        data: {
          apiKey: this.config.tileLayer.apiKey,
          gen: 9,
          jsonattributes: 1,
          mode: "trackPosition",
          pos: `${coord.lat},${coord.lng}`
        },
        dataType: "json"
      }).done((resp) => {
        if (!resp.response || !Array.isArray(resp.response.view) ||
          resp.response.view.length < 1
        ) {
          return;
        }

        const view = resp.response.view[0];
        if (!Array.isArray(view.result) || view.result.length < 1) {
          return;
        }

        const result = view.result[0];
        const address = result.location.address.label;

        $(element).val(address);
      });
    }

    addMarkers(markersData) {
      if (this.markerClusters === null) {
        this.markerClusters = L.markerClusterGroup();
        this.map.addLayer(this.markerClusters);
      }

      // Pre-compiles the template
      $.template(
        this.config.popupTemplateId,
        $(`#${this.config.popupTemplateId}`).html()
      );

      const bounds = new L.LatLngBounds(
        markersData.map(
          (markerData) => [markerData.latitude, markerData.longitude]
        )
      );

      markersData.forEach((markerData) => {
        let marker = L.marker([markerData.latitude, markerData.longitude], {
          icon: this.createIcon(),
          keyboard: true,
          title: markerData.title,
          draggable: markerData.draggable
        });

        $(marker).bind("geocoder-update-coordinates.decidim", (_event, data) => {
          $('input[data-type="latitude"]').val(data.coordinates.lat);
          $('input[data-type="longitude"]').val(data.coordinates.lng);

          if (data.targetAddress !== null) {
            this.reverseGeocoding(data.targetAddress, data.coordinates)
          }
        });

        if (markerData.draggable) {
          $(marker).trigger("geocoder-update-coordinates.decidim", {
            coordinates: {
              lat: markerData.latitude,
              lng: markerData.longitude
            }
          });

          marker.on("dragend", (ev) => {
            $(marker).trigger("geocoder-update-coordinates.decidim", {
              coordinates: ev.target.getLatLng(),
              targetAddress: "#proposal_address"
            });
          });
        } else {
          let node = document.createElement("div");

          $.tmpl(this.config.popupTemplateId, markerData).appendTo(node);

          marker.bindPopup(node, {
            maxwidth: 640,
            minWidth: 500,
            keepInView: true,
            className: "map-info"
          }).openPopup();
        }

        this.markerClusters.addLayer(marker);
      });

      this.map.fitBounds(bounds, { padding: [100, 100] });
    }

    clearMarkers() {
      this.map.removeLayer(this.markerClusters);
      this.markerClusters = L.markerClusterGroup();
      this.map.addLayer(this.markerClusters);
    }
  }

  exports.Decidim.MapMarkersController = MapMarkersController;
})(window);
