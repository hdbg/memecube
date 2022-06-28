import src/dll/mem

proc test() = echo "hello"
proc inter() = echo "before"

let h = initHook(test, inter, 6)

test()