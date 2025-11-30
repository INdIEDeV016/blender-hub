extends Node


signal request_complete(result: HTTPRequest.Result, response_error: HTTPClient.ResponseCode, headers: PackedStringArray, body: PackedByteArray)

var accept_gzip: = true
var download_file: = ""
var max_redirects: = 8
var timeout: = 0.0
var http: HTTPClient = HTTPClient.new()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func request(url: String, custom_headers: = PackedStringArray(), method: = HTTPClient.METHOD_GET, request_data: = "") -> Error:
	var err: = OK
	err = http.request(method, url, custom_headers, request_data)
	return err
