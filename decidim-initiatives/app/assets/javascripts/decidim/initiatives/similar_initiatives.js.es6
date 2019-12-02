/**
 * Update similar initiatives cards to open links in new tab
 */
$(() => {
  $(".similar-initiatives .card--initiative a").each((index, link) => {
    $(link).attr("target", "_blank");
  });
});
