# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

$(document).ready ->

	new Dragdealer 'zoom-slider'
		animationCallback: (x,y) ->
			zoom = Math.round(23 * x) + 1
			$(this.handle).text zoom
			$('#map_stitching_zoom_level').val zoom