Meteor.startup ->
  Meteor.subscribe 'queries'

Template.layout.helpers
  user: () ->
    Meteor.user()

Template.venues.helpers
  queries: ->
    Queries.find()
  venues: ->
    Session.get 'venues'
  count: ->
    Session.get('venues')?.length
  radiusArr: ->
    ['', 1,2,3,5,10,20]


getVenues = (tmp) ->
  query = $('#search').val()
  radius = $('#radius').val() or '2'
  return false unless query
  lat = tmp.map.getCenter().lat 
  lng = tmp.map.getCenter().lng
  Queries.insert 
    query: query, 
    lat: lat, 
    lng:lng, 
    radius: radius
    date: new Date()
    userId: Meteor.userId()

  # Credit Foursquare for their wonderful data
  tmp.map.attributionControl.addAttribution "<a href=\"https://foursquare.com/\">Places data from Foursquare</a>"

  # Create a Foursquare developer account: https://developer.foursquare.com/
  # NOTE: CHANGE THESE VALUES TO YOUR OWN:
  # Otherwise they can be cycled or deactivated with zero notice.
  id = "CTP4XRSRDKDXYDGUJ2DYNQNNWT1C2P4KFYTBGA5E1MJ0YPT5"
  secret = "B1SUMSUNY3XN25PJN4TDSXXKUSF3XQKV10JR12CDJ10JLQSC"

  # https://developer.foursquare.com/start/search

  latlng = "#{lat},#{lng}"
  API_ENDPOINT = "https://api.foursquare.com/v2/venues/search" + 
                  "?client_id=#{id}" + 
                  "&client_secret=#{secret}" + 
                  "&v=20130815" +
                  "&radius=#{radius*1000}" +
                  "&ll=#{latlng}" + 
                  "&query=#{query}" + 
                  "&callback=?"

  # Keep our place markers organized in a nice group.
  tmp.foursquarePlaces.clearLayers() if tmp.foursquarePlaces
  tmp.foursquarePlaces = L.layerGroup().addTo(tmp.map)

  # Use jQuery to make an AJAX request to Foursquare to load markers data.
  $.getJSON API_ENDPOINT, (result, status) =>
    return alert("Request to Foursquare failed")  if status isnt "success"
    markers = []
    _.each result.response.venues, (venue, key, list)->
      latlng = L.latLng(venue.location.lat, venue.location.lng)
      popup = "<strong><a href=\"https://foursquare.com/v/#{venue.id}\" target='_blank'>#{venue.name}</a></strong>"
      icon = icon: L.mapbox.marker.icon(
          "marker-color": "#BE9A6B"
          "marker-symbol": "restaurant"
          "marker-size": "large"
        )
      marker = L.marker(latlng, icon).bindPopup(popup).addTo(tmp.foursquarePlaces)
      markers.push marker

    #create featureGroup to fit markers inside a map
    featureGroup = new L.featureGroup(markers);
    tmp.map.fitBounds(featureGroup.getBounds());

    Session.set 'venues', result.response.venues



Template.venues.events
  "keypress #search": (e, tmp)->
    if e.keyCode is 13
      getVenues tmp

  "change #radius": (e, tmp)->
    getVenues tmp

  "click .btn-export": (e, tmp)->
    venues = Session.get('venues')
    return false unless venues 
    result = [['name', 'city', 'address', 'lat', 'lng' ]]
    _.each venues, (v)->
      l = v.location
      result.push [v.name, l.city, l.address, l.lat, l.lng]

    csvContent = "data:text/csv;charset=utf-8,"
    result.forEach (infoArray, index) ->
      dataString = infoArray.join(",")
      csvContent += (if index < infoArray.length then dataString + "\n" else dataString)
    encodedUri = encodeURI(csvContent)
    window.open encodedUri



Template.venues.rendered = ->
  #clear venues list
  Session.set 'venues', false

  #initialize
  L.mapbox.accessToken = "pk.eyJ1IjoidGltdGNoIiwiYSI6Im55Nmlxb0kifQ.Bbi850607HlgbHa1gy9KVQ"
  geocoder = L.mapbox.geocoder("mapbox.places-v1")
  @map = L.mapbox.map("map", "timtch.k1k09d8e")
  @map.scrollWheelZoom.disable()

  # panTo Tokyo 
  geocoder.query "Tokyo", (err, data) =>
    @map.setView [data.latlng[0], data.latlng[1] ], 10

Template.venues.destroyed = ->
  @map.remove()