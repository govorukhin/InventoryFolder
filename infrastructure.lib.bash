Put(){
	# Соединяет строки, перенося каждую на новую линию.
	#
	# Пример:
	# $Put aaa bbb ccc
	# aaa
	# bbb
	# ccc

	local result="$1"
	shift
	for i in "$@"; do
		result="$result\n$i"
	done
	echo -e "$result"
}
