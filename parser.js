var fs = require('fs');

var jsonString = undefined;

if (process.argv[2]) {
	jsonString = process.argv[2];
} else {
	var stdinBuffer = fs.readFileSync(0); // STDIN_FILENO = 0
	jsonString = stdinBuffer.toString();
}

console.log(JSON.parse(jsonString));
