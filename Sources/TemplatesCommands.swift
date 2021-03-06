//
// SwiftGen
// Copyright (c) 2015 Olivier Halligon
// MIT Licence
//

import Commander
import PathKit

let allSubcommands = allParserCommands.map { $0.name }

let templatesListCommand = command(
  Option<String>("only", "", flag: "l",
  description: "If specified, only list templates valid for that specific subcommand") {
    guard allSubcommands.contains($0) else {
      throw ArgumentError.invalidType(value: $0, type: "subcommand", argument: "--only")
    }
    return $0
  },
  outputOption
) { onlySubcommand, output in
  var outputLines = [String]()

  let printTemplates = { (subcommand: String, path: Path) in
    guard let files = try? (path + subcommand).children() else { return }

    for file in files where file.extension == "stencil" {
      let basename = file.lastComponentWithoutExtension
      outputLines.append("   - \(basename)")
    }
  }

  let subcommandsToList = onlySubcommand.isEmpty ? allSubcommands : [onlySubcommand]
  for subcommand in subcommandsToList {
    outputLines.append("\(subcommand):")
    outputLines.append("  custom:")
    printTemplates(subcommand, appSupportTemplatesPath)
    outputLines.append("  bundled:")
    printTemplates(subcommand, bundledTemplatesPath)
  }

  outputLines.append("---")
  outputLines.append("You can add custom templates in \(appSupportTemplatesPath).")
  outputLines.append("You can also specify templates by path using `-p PATH` instead of `-t NAME`.")
  outputLines.append("For more information, see the documentation on GitHub.")
  outputLines.append("")

  output.write(content: outputLines.joined(separator: "\n"))
}

// Defines a 'generic' command for doing an operation on a named template. It'll receive the following
// arguments from the user:
// - 'subcommand'
// - 'template'
// These will then be converted into an actual template path, and passed to the result closure.
private func templatePathCommandGenerator(execute: @escaping (Path, OutputDestination) throws -> Void) -> CommandType {
  return command(
    Argument<String>("subcommand",
      description: "the name of the subcommand for the template, like `colors`"),
    Argument<String>("template",
      description: "the name of the template to find, like `swift3` or `dot-syntax`"),
    outputOption
  ) { subcommand, name, output in
    do {
      let path = try findTemplate(subcommand: subcommand, templateShortName: name, templateFullPath: "")
      try execute(path, output)
    } catch {
      printError(string: "error: failed to read template: \(error)")
    }
  }
}

let templatesCatCommand = templatePathCommandGenerator { (path: Path, output: OutputDestination) in
  let content: String = try path.read()
  output.write(content: content)
}

let templatesWhichCommand = templatePathCommandGenerator { (path: Path, output: OutputDestination) in
  output.write(content: "\(path.description)\n")
}
