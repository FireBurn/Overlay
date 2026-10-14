"use strict";
// Krisp disabled on this libc: discord_krisp.node needs libstdc++.
const KrispModule = {
  _initialize() {},
  _getNcModels(callback) { callback([]); },
  _getVadModels(callback) { callback([]); },
  _getNcModelFilename(callback) { callback(null); },
  getNcModels: () => Promise.resolve([]),
  getVadModels: () => Promise.resolve([]),
  getNcModelFilename: () => Promise.resolve(null),
};
module.exports = KrispModule;
