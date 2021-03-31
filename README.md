# CodeRunner-Mavericks-Workarounds
Fixes CodeRunner 3.1 (https://coderunnerapp.com/) on OS X 10.9 Mavericks. Unaffiliated with the original developer.

1. Compile the code.
2. Rename the binary (a file _inside_ the compiled .framework) to CodeRunnerMavericksWorkarounds.dylib.
3. Copy CodeRunnerMavericksWorkarounds.dylib to CodeRunner.app/Contents/Frameworks/
4. insert_dylib --inplace @executable_path/../Frameworks/CodeRunnerMavericksWorkarounds.dylib /Applications/CodeRunner.app/Contents/MacOS/CodeRunner
