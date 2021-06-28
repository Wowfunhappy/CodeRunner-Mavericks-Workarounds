# CodeRunner-Mavericks-Workarounds
Fixes CodeRunner 3.1 (https://coderunnerapp.com/) on OS X 10.9 Mavericks. Unaffiliated with the original developer.

## Installation Instructions
1. Download CodeRunner 3.1 from https://coderunnerapp.com/blog/releasenotes/3.1/.
2. Right click CodeRunner.app and select "Show Package Contents" to see what's inside.
3. Download CodeRunnerMavericksWorkarounds.zip from [Releases](https://github.com/Wowfunhappy/CodeRunner-Mavericks-Workarounds/releases)
4. Copy the files in CodeRunnerMavericksWorkarounds.zip to the associated locations inside of CodeRunner.app.

## Building
1. Compile the code.
2. Rename the binary (a file _inside_ the compiled .framework) to CodeRunnerMavericksWorkarounds.dylib.
3. Copy CodeRunnerMavericksWorkarounds.dylib to CodeRunner.app/Contents/Frameworks/
4. insert_dylib --inplace @executable_path/../Frameworks/CodeRunnerMavericksWorkarounds.dylib /Applications/CodeRunner.app/Contents/MacOS/CodeRunner
