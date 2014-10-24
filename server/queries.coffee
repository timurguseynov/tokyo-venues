Meteor.publish "queries", ->
  if @userId then Queries.find userId: @userId else @ready()

