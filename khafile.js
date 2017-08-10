let project = new Project('Empty');

project.addAssets('Assets/**', {quality: 0.5});
project.addSources('Sources');

resolve(project);
