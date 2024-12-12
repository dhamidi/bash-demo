#!/usr/bin/env node
const vm = require("node:vm");
const process = require("node:process");
const fs = require("node:fs");

const state = {
  currentModel: null,
  models: new Map(),
};
const emit = () => {
  let lines = [];
  for (let model of state.models.values()) {
    lines.push(`const ${model.name}Schema = Types.Object({`);
    for (let [fieldName, fieldType] of Object.entries(model.fields)) {
      lines.push(`  ${fieldName}: ${Symbol.keyFor(fieldType)},`);
    }
    lines.push(`})`);
  }
  console.log(lines.join("\n"));
};
const ModelGeneratorDSL = {
  model(name) {
    let modelObject = state.models.get(name);
    if (!modelObject) {
      modelObject = {
        name: name,
        fields: {},
      };
      state.models.set(name, modelObject);
    }
    state.currentModel = modelObject;
  },
  field(name, type) {
    state.currentModel.fields[name] = type;
  },
  Types: {
    Date: Symbol.for("Types.Date"),
    String: Symbol.for("Types.String"),
  },
  emit,
  console,
};

const context = vm.createContext(ModelGeneratorDSL);
const sourceFileName = process.argv[2];
let sourceFileCode = fs.readFileSync(sourceFileName).toString("utf-8");
let lineOffset = 0;
if (sourceFileCode.startsWith("#")) {
  sourceFileCode = sourceFileCode.replace(/^#.*\n/m, "");
  lineOffset = 1;
}
const script = new vm.Script(sourceFileCode, {
  filename: sourceFileName,
  lineOffset,
});
script.runInContext(context);
