// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.
// require materialize-tags/dist/js/materialize-tags.min.js
//= require selectize/dist/js/standalone/selectize.js
// require typeahead
//= require sweetalert
// require_tree .
//= require init
//= require triggers
//= require_tree ./abstracted

// <!DOCTYPE html>
// <form method="post" action="?" disablemultiplesubmits>
//   <button type="submit">click me</button>
// </form>
// // at the end of the page
// disableMultipleSubmits();
//
// // or within a defer or a non async script
// document.addEventListener('DOMContentLoaded', disableMultipleSubmits, false);
// $(document).ready(function(){
//   function disableMultipleSubmits() { // by Andrea Giammarchi - WTFPL
//     Array.prototype.forEach.call(
//       document.querySelectorAll('form[disablemultiplesubmits]'),
//       function (form) {
//         form.addEventListener('submit', this, true);
//       },
//       {
//         // button to disable
//         query: 'input[type=submit],button[type=submit]',
//         // delay before re-enabling
//         delay: 500,
//         // handler
//         handleEvent: function (e) {
//           var button = e.currentTarget.querySelector(this.query);
//           button.disabled = true;
//           setTimeout(function () {
//             console.log('submit re-enabled');
//             button.disabled = false;
//           }, this.delay);
//         }
//       }
//     );
//   }
// });
