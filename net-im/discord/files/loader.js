// Discord resolves its resources relative to Electron's own dist directory.
// Running its app.asar with the system Electron would look in the wrong
// place, so point it at this installation before loading the app unchanged.
const path = require('node:path')

const resources = path.join(__dirname, '..')
Object.defineProperty(process, 'resourcesPath', { value: resources })

require(path.join(resources, 'app.asar'))
