package main

import "fmt"

type MyStruct struct {
	Field1 int
	Field2 string
}

func Fn(x int) (int, int, string) {
	y := 7
	z := fmt.Sprintf("Value: %d", y)
	z += "!"

	// fmt.Printf("Value: %d", y)

	struct{ a int }{a: (5 + 8) + 2}

	MyStruct{Field1: y, Field2: z}

	return x*x + y*3, y, z
}

func Func() string {
	x, y, z := Fn(5)

	return fmt.Sprintf("Results: x=%d, y=%d, z=%s", x, y, z)
}

func main() {
	fmt.Println(Func())
}
