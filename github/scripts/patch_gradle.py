import sys

path = sys.argv[1]
with open(path) as f:
    content = f.read()

if "isCoreLibraryDesugaringEnabled" not in content:
    content = content.replace(
        "compileOptions {",
        "compileOptions {\n        isCoreLibraryDesugaringEnabled = true",
        1
    )

if "coreLibraryDesugaring" not in content:
    content += '\n\ndependencies {\n    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")\n}\n'

with open(path, 'w') as f:
    f.write(content)

print("Patched:", path)
