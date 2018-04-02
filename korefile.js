let fs = require('fs');
let path = require('path');
let project = new Project('PhysicsSample');
project.targetOptions = {"html5":{},"flash":{},"android":{},"ios":{}};
project.setDebugDir('build/windows');
await project.addProject('build/windows-build');
await project.addProject('C:/Users/Marian/KOM/KhaDev/Kha');
if (fs.existsSync(path.join('Libraries/Bullet', 'korefile.js'))) {
	await project.addProject('Libraries/Bullet');
}
resolve(project);
