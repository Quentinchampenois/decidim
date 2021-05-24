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

    if ($checkbox.is(":checked")) {
      $map.show()
    }

    const getCoordinateInputName = (coordinate, $input, options) => {
      const key = `${coordinate}Name`;
      if (options[key]) {
        return options[key];
      }

      const inputName = $input.attr("name");
      const subNameMatch = /\[[^\]]+\]$/;
      if (inputName.match(subNameMatch)) {
        return inputName.replace(subNameMatch, `[${coordinate}]`);
      }

      return coordinate;
    }

    const ctrl = $("[data-decidim-map]").data("map-controller")

    ctrl.setEventHandler("coordinates", (ev) => {
      const latFieldName = getCoordinateInputName("latitude", $addressInputField, {})
      const longFieldName = getCoordinateInputName("longitude", $addressInputField, {})
      const $latField = $("input[name='"+ latFieldName +"']")
      const $longField = $("input[name='"+ longFieldName +"']")
      $latField.val(ev.lat)
      $longField.val(ev.lng)
    })

    attachGeocoding($addressInputField, null, (coordinates) => {
      $map.show()

      ctrl.removeMarker()
      ctrl.addMarker({
        latitude: coordinates[0],
        longitude: coordinates[1],
        address: $addressInput.val()
      })

      ctrl.setEventHandler("coordinates", (ev) => {
        console.log("nonononon")
        const latFieldName = getCoordinateInputName("latitude", $addressInputField, {})
        const longFieldName = getCoordinateInputName("longitude", $addressInputField, {})
        const $latField = $("input[name='"+ latFieldName +"']")
        const $longField = $("input[name='"+ longFieldName +"']")
        $latField.val(ev.lat)
        $longField.val(ev.lng)
      })

      // ctrl.reload();
    });
  }
});
