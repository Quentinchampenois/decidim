import attachGeocoding from "src/decidim/geocoding/attach_input"

$(() => {
  const $checkbox = $("input:checkbox[name$='[has_address]']");
  const $addressInput = $("#address_input");
  const $addressInputField = $("input", $addressInput);
  const $map = $("#address_map");

  $map.hide();
  if ($checkbox.length > 0) {
    const toggleInput = () => {
      if ($checkbox[0].checked) {
        $addressInput.show();
        $addressInputField.prop("disabled", false);
      } else {
        $addressInput.hide();
        $addressInputField.prop("disabled", true);
      }
    }
    toggleInput();
    $checkbox.on("change", toggleInput);
  }

  if ($addressInput.length > 0) {
    attachGeocoding($addressInputField, null, (coordinates) => {
      $map.show()

      const markerData = {
        latitude: coordinates[0],
        longitude: coordinates[1],
        address: $addressInput.val()
      }

      const config = $("[data-decidim-map]").data("map-controller").getConfig()
      config.marker.latitude = markerData.latitude;
      config.marker.longitude = markerData.longitude;
      config.marker.address = markerData.address;
      $("[data-decidim-map]").data("mapController").start();
    });
  }
});
