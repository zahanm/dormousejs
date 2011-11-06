
###

Task structure on API

{
  id: 1234,
  name: "ManReduce-Step-1",
  project_id: 11,
  template_id: 7,
  duplication: 1,
  replication: 1,
  created_at; "2011-10-14T14:02:47Z",
  updated_at: "2011-10-14T14:02:47Z",
  expires_at: "",
  eligibility: {
    communities: [],
    predicate: null
  },
  parameters: {
    question: "blah"
  }
}

###

path = require 'path'
Connection = require('./connection').Connection

###
* Tasks mixin for Dormouse
* basic API operations
###
class Tasks extends Connection

  ###
  @param ids = ids of tasks to fetch, optional
  ###
  getTasks: (ids, callback) ->
    get_path = 'tasks.json'
    args = Array::concat.apply [ get_path ], arguments
    return this.getIds.apply this, args

  ###
  @param task_info = object with the following required fields
      project_id. template_id, parameters
    and the following optional fields
      eligibility, expires_at, replication, duplication, name
  @callback { status: 'created', location: 1234 }
  ###
  createTask: (task_info, callback) ->
    required_fields = ['project_id', 'template_id', 'parameters']
    for field in required_fields
      throw new Error "Required field for task creation: #{field}" unless field in task_info
    post_path = 'tasks.json'
    return this.post post_path, { 'task': task_info }, callback

  performTask: (task, callback) ->
    get_path = path.join 'tasks', task.id, 'perform.json'
    return this.get get_path, callback

  answerTask: (task, answer_info, callback) ->
    put_path = path.join 'tasks', task.id, 'answer.json'
    return this.put put_path, answer_info, callback

  deleteTask: (task, callback) ->
    delete_path = path.join 'tasks', "#{task.id}.json"
    return this.delete delete_path, callback

exports.Tasks = Tasks