extends GutTest


func test_empty():
	var a = GridUtil.blit_rect(PackedByteArray(), Vector2i.ZERO, Rect2i(), PackedByteArray(), Vector2i.ZERO, Vector2i.ZERO)
	assert_eq(a, PackedByteArray())


func test_single():
	var a = GridUtil.blit_rect(PackedByteArray([1]), Vector2i.ONE, Rect2i(Vector2i.ZERO, Vector2i.ONE), PackedByteArray([0]), Vector2i.ONE, Vector2i.ZERO)
	assert_eq(a, PackedByteArray([1]))


func test_four():
	var a = GridUtil.blit_rect(PackedByteArray([0, 1, 0, 1]), Vector2i.ONE * 2, Rect2i(Vector2i.ZERO, Vector2i.ONE * 2), PackedByteArray([1, 0, 1, 0]), Vector2i.ONE * 2, Vector2i.ZERO)
	assert_eq(a, PackedByteArray([0, 1, 0, 1]))


func test_partial():
	var src = PackedByteArray()
	var src_size = Vector2i(3, 3)
	for i in range(9):
		src.push_back(i)
	var dst = PackedByteArray()
	var dst_size = Vector2i(5, 5)
	for i in range(25):
		dst.push_back(i)
	var a = GridUtil.blit_rect(src, src_size, Rect2i(Vector2i.ZERO, src_size), dst, dst_size, Vector2i.ONE)
	var expected = PackedByteArray([
		0 ,1 ,2 ,3 ,4 ,
		5 ,0 ,1 ,2 ,9 ,
		10,3 ,4 ,5 ,14,
		15,6 ,7 ,8 ,19,
		20,21,22,23,24,
	])
	assert_eq(a, expected)
