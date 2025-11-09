signal output(value: int)

var inputs: Array[int]
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


func add_input(input: int):
	_mutex.lock()
	inputs.push_back(input)
	_mutex.unlock()
	_semaphore.post()


func add_input_batched(input: Array[int]):
	_mutex.lock()
	inputs.append_array(input)
	_mutex.unlock()
	_semaphore.post()


func _work():
	while true:
		_semaphore.wait()
		_mutex.lock()
		if _thread_stopped:
			_mutex.unlock()
			break
		else:
			_mutex.unlock()

		_mutex.lock()
		for v in inputs:
			output.emit.call_deferred(v * v)
		inputs.clear()
		_mutex.unlock()
