var fs = require('fs');

let json = undefined;
let user_id = undefined;

if (process.argv[2] && process.argv[3]) {
	user_id = process.argv[2];
	json = process.argv[3];
} else {
	// console.log("reading json from stdin...");
	let stdinBuffer = fs.readFileSync(0); // STDIN_FILENO = 0
	json = stdinBuffer.toString();
	user_id = process.argv[2];
}

if (!user_id) throw new Error("user id wasn't provided");

let tasks = JSON.parse(json);
loop: for (let t in tasks) {
	let task = tasks[t];
	for (let a in task.assignments) {
		let assignment = task.assignments[a];
		
		if (user_id == assignment.assignee_id) {
			console.log(task.id);
			break loop;
		}
	}
}