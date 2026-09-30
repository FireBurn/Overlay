// Discord resolves its resources relative to Electron's own dist directory.
// Running its app.asar with the system Electron would look in the wrong
// place, so point it at this installation before loading the app unchanged.
const path = require('node:path')

const resources = path.join(__dirname, '..')
Object.defineProperty(process, 'resourcesPath', { value: resources })

// Discord 1.0.160 derives its resources directory, and so the location of the
// bootstrap modules, from the main module's path, which is just "electron"
// under the system Electron.
require.main.filename = path.join(resources, 'app.asar', 'bundle.js')

require(path.join(resources, 'app.asar'))
