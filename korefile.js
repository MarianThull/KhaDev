let fs = require('fs');
let path = require('path');
let project = new Project('AndrNatDebug', __dirname);
project.targetOptions = {"html5":{},"flash":{},"android":{},"ios":{}};
project.setDebugDir('build/android-native');
Promise.all([Project.createProject('build/android-native-build', __dirname), Project.createProject('C:/Users/Dev/KOM/KhaDev/kha', __dirname), Project.createProject('C:/Users/Dev/KOM/KhaDev/kha/Kore', __dirname)]).then((projects) => {
	for (let p of projects) project.addSubProject(p);
	let libs = [];
	Promise.all(libs).then((libprojects) => {
		for (let p of libprojects) project.addSubProject(p);
		resolve(project);
	});
});
