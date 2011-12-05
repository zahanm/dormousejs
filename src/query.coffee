
_ = require 'underscore'
Connection = require('./connection').Connection

# Task top level properties
top_level =
  id: true
  name: true
  project_id: true
  template_id: true
  duplication: true
  replication: true
  created_at: true
  updated_at: true
  expires_at: true

###
* Query for tasks
* Rich query mechanism
###

class Query extends Connection

  constructor: ->
    @get_path = 'tasks.json'
    @constraints = []
    @ordering = false
    @limited = false

  where: (prop, value) ->
    @constraints.push prop: prop, value: value

  check_constraints: (task) ->
    @constraints.every (c) ->
      if c.prop of top_level
        task[c.prop] is c.value
      else
        task.parameters[c.prop] is c.value

  order_by: (o) ->
    @ordering = o

  apply_ordering: (tasks) ->
    if @ordering is '?'
      _.shuffle tasks
    else
      _.sortBy tasks, (task) ->
        if @ordering of top_level
          task[@ordering]
        else
          task.parameters[@ordering]
      , this

  limit: (l) ->
    @limited = l

  run: (callback) ->
    Query.get @get_path, (r) =>
      tasks = r.map (t) ->
        t.task
      tasks = tasks.filter @check_constraints, this
      if @ordering
        tasks = @apply_ordering tasks
      if @limited
        tasks = tasks.slice 0, @limited
      callback tasks

exports.Query = Query
