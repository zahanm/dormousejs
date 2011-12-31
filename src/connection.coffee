
path = require 'path'
_ = require 'underscore'
http = require 'http-browserify'

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
      query: appendAPIKey options
    req = http.request
      method: 'GET'
      host: Connection.host()
      port: Connection.port()
      path: get_path
    , (res) ->
      handleResponse res, callback
    req.end() # sends the request

  # @param options appended to URL
  # @param body dumped in POST body
  @post: (post_path, options, body, callback) ->
    post_path = libutils.formatUrl
      path: post_path
      query: appendAPIKey options
    raw_body = JSON.stringify body
    raw_length = if Buffer? then Buffer.byteLength(raw_body) else raw_body.length
    req = http.request
      method: 'POST'
      host: Connection.host()
      port: Connection.port()
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
      query: appendAPIKey options
    raw_body = JSON.stringify body
    raw_length = if Buffer? then Buffer.byteLength(raw_body) else raw_body.length
    req = http.request
      method: 'PUT'
      host: Connection.host()
      port: Connection.port()
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
      query: appendAPIKey options
    req = http.request
      method: 'DELETE'
      host: Connection.host()
      port: Connection.port()
      path: delete_path
    , (res) ->
      handleResponse res, callback
    req.end()

  host = 'dormou.se'
  port = 80
  @server: (setter) ->
    if setter
      matched = setter.match /^((https?):\/\/)?([A-Za-z0-9\.]+)(:(\d+))?\/?$/
      if matched
        host = matched[3] || 'dormou.se'
        port = matched[5] || 80
      else
        throw new Error 'Improperly formatted url passed to Dormouse.server(...)'
    "http://#{host}:#{port}/"

  @host: (setter) ->
    if setter
      host = setter
    host

  @port: (setter) ->
    if setter
      port = setter
    port

  api_key = ''
  @api_key: (setter) ->
    if setter
      api_key = setter
    unless api_key
      throw new Error 'You cannot make API calls without an api_key. Set it using Dormouse.api_key(...)'
    api_key

#### Private methods
# No one can access these from the outside

appendAPIKey = (options) ->
  return _.extend options, api_key: Connection.api_key()

handleResponse = (res, callback) ->
  data = ''
  res.on 'data', (buf) ->
    data += buf
  res.on 'end', () ->
    parseResponse res, data, callback if callback
  res.on 'error', (err) ->
    console.log 'HTTP error', res.statusCode, data, err

parseResponse = (res, raw_response, callback) ->
  raw_response = raw_response.trim()
  if res.statusCode is 200 # STATUS: OK
    if raw_response
      try
        callback null, JSON.parse raw_response
      catch err
        console.error 'Response JSON parsing error', err if console
    else
      callback null, success: true
  else
    console.info 'Request failed', raw_response if console
    callback new Error(raw_response), null

exports.Connection = Connection
