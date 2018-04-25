let fs = require('fs');
let path = require('path');
let project = new Project('PhysicsSample');
project.targetOptions = {"html5":{},"flash":{},"android":{},"ios":{}};
project.setDebugDir('build/html');
await project.addProject('build/html-build');
await project.addProject('C:/Users/Dev/KOM/KhaDev/kha');
if (fs.existsSync(path.join('Libraries/Bullet', 'korefile.js'))) {
	await project.addProject('Libraries/Bullet');
}
resolve(project);
