package main
import (
	"fmt"
	"os"
)
func main() {
	fmt.Println("sun-cipher running, id:", os.Getenv("SUN_CIPHER_ID"))
}
