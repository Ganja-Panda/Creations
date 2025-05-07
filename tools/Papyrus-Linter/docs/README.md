# Papyrus Linter Design with SonarQube

## Overview

Developing a static code analyzer (linter) for Bethesda’s **Papyrus** scripting language requires understanding both Papyrus’s unique language characteristics and SonarQube’s plugin architecture. Papyrus is an **object-oriented, event-driven** language used in Skyrim, Fallout 4/76, and (soon) Starfield. Unlike modern OOP languages, Papyrus has a number of idiosyncrasies – such as strict line-oriented syntax, limited operators, and a focus on game event handling – which demand custom rule design. Leveraging SonarQube as the analysis framework is feasible via a custom language plugin, enabling integration with SonarQube’s dashboards and SonarLint for IDE feedback. This research compiles technical notes on Papyrus syntax/semantics, proposes linter rule sets and logic, outlines SonarQube integration steps, and addresses performance, testing, and future considerations (e.g. Starfield’s Papyrus updates and potential VSCode extension packaging).

## Papyrus Language Fundamentals

Papyrus was introduced with Skyrim’s Creation Kit as a replacement for older Bethesda scripting systems, bringing a new syntax and workflow. It is a **strongly and explicitly typed** language – variables, properties, and function return types must be declared with concrete types (e.g. `Int`, `Float`, `ObjectReference`). The language model is **object-oriented**: scripts are essentially classes that can extend base classes, and script instances are attached to game objects. Papyrus emphasizes an **event-driven design**: the runtime sends events (like `OnInit()`, `OnActivate()`, etc.) to script instances, and the script’s event handler functions respond. In practice, Papyrus “focuses on player actions and then responds with specific events in the game” – for example, a door object’s script might implement an `OnActivate` event to run code when the player uses the door.

## Papyrus Syntax and Semantics

To build a linter, we need a precise **grammar** for Papyrus. Papyrus’s syntax has some legacy quirks inherited from its heritage (it evolved from Oblivion’s older scripting language). Key syntax/semantic elements to account for:

* **Statements & Blocks:** Papyrus uses newline-separated statements. Indentation is not significant to the compiler (only for human readability), so the linter must rely on keywords to determine blocks. Each control structure has a matching end keyword (e.g. `If/EndIf`, `While/EndWhile`, `Function/EndFunction`, `Event/EndEvent`, `State/EndState`). The grammar should ensure every opening has a closing, and the linter can flag mismatched or missing `End` markers. Proper **nesting** is enforced by the compiler, and the linter can similarly track a stack of open blocks to validate scope.

* **Expressions:** Papyrus expressions include arithmetic (`+ - * /`), comparisons (`==`, `!=`, `>` etc.), boolean logic (`AND`, `OR`, `NOT`), and type casts. Papyrus supports implicit conversion of some types (e.g. a `None` object reference is treated as false in conditionals), so `If SomeActorRef` is valid and equivalent to `If SomeActorRef != None`. There is **no ternary operator**, so conditional logic always uses `If/Else` blocks.

* **Properties and Variables:** Properties are declared outside functions with the `Property` keyword, optionally marked `Auto` to generate getter/setter. Variables are explicitly typed and must be initialized before use. The linter should differentiate between fields, properties, and local variables, and track scope accordingly.

* **Typing and References:** Papyrus is **strongly typed** – an integer cannot be used where a string is expected, etc., without an explicit cast. All object types in Papyrus inherit from a common `Form` type (or `ObjectReference` for placed objects). The linter can build a rudimentary **symbol table** per script to track variable types and ensure consistency.

## Designing Linter Rules for Papyrus

A Papyrus linter should catch both general coding issues *and* Papyrus-specific pitfalls. The goal is a **context-aware rule set** that understands Papyrus’s strictness and best practices. Key categories of rules to implement:

* **Syntax and Scope Issues:** Unclosed blocks, unused variables, redeclared variables, missing end markers.
* **Dead Code and Unreachable Code:** Unreachable code after returns, empty loops, and empty conditionals.
* **Variable Tracking and Usage:** Efficient static analysis with a **symbol table** to detect unused variables, shadowing, and scope violations.
* **Papyrus Best Practice Rules:** Rules to avoid performance issues, like deep nesting, redundant comparisons, and unhandled events.

## SonarQube Integration (Custom Language Plugin)

Integrating Papyrus analysis into SonarQube involves developing a **SonarQube language plugin** for Papyrus. Steps include defining the language, building a parser, implementing rule visitors, and packaging the plugin for SonarQube deployment.

## Testing and Validation

Rigorous testing is crucial for the linter’s reliability. This includes unit tests, integration tests on real mods, and continuous validation against known good/bad code patterns. Testing should cover syntax parsing, rule accuracy, and performance.

## Future Outlook and Additional Considerations

The linter should be designed for extensibility, potentially supporting future Bethesda titles like Starfield. A VSCode extension or direct integration with Papyrus compilers can improve adoption and usability.
