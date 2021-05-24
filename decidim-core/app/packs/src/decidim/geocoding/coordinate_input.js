export default function getCoordinateInputName(coordinate, $input, options) {
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
