import re

def clean_pbxproj(file_path):
    with open(file_path, 'r') as f:
        content = f.read()
    
    # Remove FlutterGeneratedPluginSwiftPackage lines
    content = re.sub(r'[A-F0-9]{24} /\* FlutterGeneratedPluginSwiftPackage \*/,\n', '', content)
    content = re.sub(r'[A-F0-9]{24} /\* FlutterGeneratedPluginSwiftPackage in Frameworks \*/,\n', '', content)
    
    # Remove Xcode local package reference blocks
    content = re.sub(r'\s+[A-F0-9]{24} /\* FlutterGeneratedPluginSwiftPackage \*/ = \{\n\s+isa = PBXFileReference;\n\s+lastKnownFileType = folder;\n\s+name = FlutterGeneratedPluginSwiftPackage;\n\s+path = Flutter/ephemeral/Packages/FlutterGeneratedPluginSwiftPackage;\n\s+sourceTree = "<group>";\n\s+\};\n', '', content)
    
    with open(file_path, 'w') as f:
        f.write(content)

clean_pbxproj('MacOS/Runner.xcodeproj/project.pbxproj')
