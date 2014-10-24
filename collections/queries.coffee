@Queries = new Meteor.Collection("queries")

ownsDocument = (userId, doc) ->
  doc and doc.userId is userId

Queries.allow
  update: ownsDocument
  remove: ownsDocument

  insert: (userId)->
    userId #need tests

# Queries.allow update: (userId, doc, fieldNames) ->
#   _.without(fieldNames, "userId").length > 0
