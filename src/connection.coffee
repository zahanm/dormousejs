
path = require 'path'
_ = require 'underscore'
http = require 'http-browserify'

Store = require('./store').Store
libutils = require './libutils'

#### Connection for us all
# Used as a base class that provides simple `.get()` and `.post()` access
# to the relevant http methods
#
# Inspiration from Ruby's `httparty`
class Connection

  # Assumption that it is getting JSON
  # @param options serialized in GET params
  @get: (get_path, options, callback) ->
    if typeof options is 'function'
      callback = options
      options = {}
    get_path = libutils.formatUrl
      path: get_path
      query: signRequest options
    req = http.request
      method: 'GET'
      host: Store.host()
      port: Store.port()
      path: get_path
    , (res) ->
      handleResponse res, callback
    req.end() # sends the request

  # @param options appended to URL
  # @param body dumped in POST body
  @post: (post_path, options, body, callback) ->
    post_path = libutils.formatUrl
      path: post_path
      query: signRequest options
    raw_body = JSON.stringify body
    raw_length = if Buffer? then Buffer.byteLength(raw_body) else raw_body.length
    req = http.request
      method: 'POST'
      host: Store.host()
      port: Store.port()
      path: post_path
      headers:
        'Content-Type': 'application/json'
        'Content-Length': raw_length
    , (res) ->
      handleResponse res, callback
    req.end raw_body

  # @param options appended to URL
  # @param body dumped in body
  @put: (put_path, options, body, callback) ->
    put_path = libutils.formatUrl
      path: put_path
      query: signRequest options
    raw_body = JSON.stringify body
    raw_length = if Buffer? then Buffer.byteLength(raw_body) else raw_body.length
    req = http.request
      method: 'PUT'
      host: Store.host()
      port: Store.port()
      path: put_path
      headers:
        'Content-Type': 'application/json'
        'Content-Length': raw_length
    , (res) ->
      handleResponse res, callback
    req.end raw_body

  # @param options is optional
  @delete: (delete_path, options, callback) ->
    delete_path = libutils.formatUrl
      path: delete_path
      query: signRequest options
    req = http.request
      method: 'DELETE'
      host: Store.host()
      port: Store.port()
      path: delete_path
    , (res) ->
      handleResponse res, callback
    req.end()

#### Private methods
# No one can access these from the outside

signRequest = (options) ->
  if 'access_token' of options or 'api_key' of options
    options
  else if Store.access_token()
    _.extend options, access_token: Store.access_token()
  else
    _.extend options, api_key: Store.api_key()

handleResponse = (res, callback) ->
  data = ''
  res.on 'data', (buf) ->
    data += buf
  res.on 'end', () ->
    parseResponse res, data, callback if callback
  res.on 'error', (err) ->
    console.log 'HTTP error', res.statusCode, data, err

# STATUS: OK, CREATED, ACCEPTED
successful_statuses = [ 200, 201, 202 ]

parseResponse = (res, raw_response, callback) ->
  raw_response = raw_response.trim()
  if res.statusCode in successful_statuses
    if raw_response
      try
        response = JSON.parse raw_response
      catch err
        console.error 'Response JSON parsing error', err if console
      callback null, response
    else
      callback null, success: true
  else
    if console
      console.info 'Req failed', raw_response, 'code', res.statusCode
      # XXX private api
      console.info 'Fetch path', res.connection._httpMessage.path
    callback new Error(raw_response), null

exports.Connection = Connection
