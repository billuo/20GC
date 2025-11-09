class_name Solver
extends Node

signal solved(moves: Array[AnalyzedMove])

var inputs: Array[PackedByteArray]
var timestamps: Array[int]
var _thread_stopped := false
var _mutex: Mutex
var _semaphore: Semaphore
var _thread: Thread


func _ready():
	_mutex = Mutex.new()
	_semaphore = Semaphore.new()
	_thread = Thread.new()
	start_thread()


func _exit_tree():
	stop_thread()


func start_thread():
	_thread.start(_work)


func stop_thread():
	_mutex.lock()
	_thread_stopped = true
	_mutex.unlock()
	_semaphore.post()
	_thread.wait_to_finish()


func solve_position(moves: PackedByteArray) -> void:
	_mutex.lock()
	inputs.push_back(moves)
	timestamps.push_back(Time.get_ticks_usec())
	_mutex.unlock()
	_semaphore.post()


func _work():
	const MIN_THINKING_DELAY = 100 * 1000
	var solver := C4Solver.new()
	while true:
		_semaphore.wait()
		_mutex.lock()
		var exit = _thread_stopped
		_mutex.unlock()
		if exit:
			break

		_mutex.lock()
		for i in range(inputs.size()):
			var moves = solver.analyze(inputs[i], false)
			var now = Time.get_ticks_usec()
			var time_left = timestamps[i] + MIN_THINKING_DELAY - now
			if time_left <= 0:
				solved.emit.call_deferred(moves)
			else:
				get_tree().create_timer(time_left / 1000000.0).timeout.connect(func(): solved.emit.call_deferred(moves))
		inputs.clear()
		timestamps.clear()
		_mutex.unlock()
