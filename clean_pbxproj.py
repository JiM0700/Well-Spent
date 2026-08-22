import re
import sys

def clean_pbxproj(file_path):
    with open(file_path, 'r') as f:
        content = f.read()
    
    # Remove all lines containing 'Pods-Runner' or 'Flutter' or '[CP]'
    lines = content.split('\n')
    new_lines = []
    skip_block = False
    brace_count = 0
    
    # Simpler regex approach for build phases
    # Remove references to Pods in PBXFrameworksBuildPhase
    content = re.sub(r'[A-F0-9]{24} /\* Pods_Runner.framework in Frameworks \*/,\n', '', content)
    content = re.sub(r'[A-F0-9]{24} /\* sqflite_darwin.framework in Frameworks \*/,\n', '', content)
    
    # Remove the "[CP] Embed Pods Frameworks" and "[CP] Check Pods Manifest.lock" build phases from the native target
    content = re.sub(r'[A-F0-9]{24} /\* \[CP\].*?\*/,\n', '', content)
    content = re.sub(r'[A-F0-9]{24} /\* Run Script \*/,\n', '', content)
    content = re.sub(r'[A-F0-9]{24} /\* Thin Binary \*/,\n', '', content)
    content = re.sub(r'[A-F0-9]{24} /\* Flutter Assemble \*/,\n', '', content)

    # Let's completely remove xcconfig includes from the pbxproj
    content = re.sub(r'baseConfigurationReference = [A-F0-9]{24} /\* .*?\.xcconfig \*/;', '', content)
    
    with open(file_path, 'w') as f:
        f.write(content)

clean_pbxproj('ios/Runner.xcodeproj/project.pbxproj')
clean_pbxproj('MacOS/Runner.xcodeproj/project.pbxproj')
