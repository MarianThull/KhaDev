let project = new Project('Project');

project.addAssets('Assets/**');
project.addSources('Sources');
project.addShaders('Shaders/**');

resolve(project);
