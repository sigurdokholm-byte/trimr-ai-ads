#!/usr/bin/env python3
"""Generate a minimal project.pbxproj for the TRIMR iOS app."""
import os, sys

ROOT = os.path.dirname(os.path.abspath(__file__))
APP = "TRIMR"
SRC_DIR = os.path.join(ROOT, APP)

swift_files = []
for dirpath, dirs, files in os.walk(SRC_DIR):
    # Skip asset dirs
    rel = os.path.relpath(dirpath, SRC_DIR)
    if any(part.endswith(".xcassets") or part == "Preview Content" for part in rel.split(os.sep)):
        continue
    for f in sorted(files):
        if f.endswith(".swift"):
            full = os.path.join(dirpath, f)
            rel_path = os.path.relpath(full, SRC_DIR)
            swift_files.append(rel_path)

swift_files.sort()

counter = [0]
def nid():
    counter[0] += 1
    return f"AA{counter[0]:022X}"

# Assign IDs
file_refs = {}   # rel_path -> PBXFileReference id
build_files = {} # rel_path -> PBXBuildFile id
for rp in swift_files:
    file_refs[rp] = nid()
    build_files[rp] = nid()

assets_fileref = nid()
assets_buildfile = nid()
preview_assets_fileref = nid()
preview_assets_buildfile = nid()
infoplist_fileref = nid()

# Groups
main_group = nid()
product_group = nid()
app_group = nid()
screens_group = nid()
onboarding_group = nid()
preview_group = nid()

app_target = nid()
app_product_ref = nid()
project_id = nid()
sources_phase = nid()
resources_phase = nid()
frameworks_phase = nid()
config_list_project = nid()
config_list_target = nid()
config_debug_project = nid()
config_release_project = nid()
config_debug_target = nid()
config_release_target = nid()

# Group children by directory
# Structure:
# TRIMR (app_group)
#   TRIMRApp.swift
#   Theme.swift, Components.swift, RootView.swift, Models.swift
#   Info.plist
#   Assets.xcassets
#   Screens (screens_group)
#     *.swift
#     Onboarding (onboarding_group)
#       *.swift
#   Preview Content (preview_group)
#     Preview Assets.xcassets

root_files = []
screens_files = []
onboarding_files = []
networking_files = []
networking_models_files = []
for rp in swift_files:
    if rp.startswith("Screens/Onboarding/"):
        onboarding_files.append(rp)
    elif rp.startswith("Screens/"):
        screens_files.append(rp)
    elif rp.startswith("Networking/Models/"):
        networking_models_files.append(rp)
    elif rp.startswith("Networking/"):
        networking_files.append(rp)
    else:
        root_files.append(rp)

networking_group = nid()
networking_models_group = nid()

# --- Swift Package dependencies (Supabase) ---
# Code only `import Supabase`; everything else is a system framework.
SUPABASE_REPO_URL = "https://github.com/supabase/supabase-swift"
SUPABASE_MIN_VERSION = "2.44.0"
SUPABASE_PRODUCTS = ["Supabase"]
supabase_pkg_ref = nid()
supabase_product_deps = {p: nid() for p in SUPABASE_PRODUCTS}
supabase_framework_buildfiles = {p: nid() for p in SUPABASE_PRODUCTS}

def quote(s):
    if any(c in s for c in ' /.'): return f'"{s}"'
    return s

# --- Build pbxproj ---
lines = []
lines.append("// !$*UTF8*$!")
lines.append("{")
lines.append("\tarchiveVersion = 1;")
lines.append("\tclasses = {};")
lines.append("\tobjectVersion = 56;")
lines.append("\tobjects = {")

# PBXBuildFile
lines.append("\n/* Begin PBXBuildFile section */")
for rp in swift_files:
    bf = build_files[rp]; fr = file_refs[rp]
    name = os.path.basename(rp)
    lines.append(f'\t\t{bf} /* {name} in Sources */ = {{isa = PBXBuildFile; fileRef = {fr} /* {name} */; }};')
lines.append(f'\t\t{assets_buildfile} /* Assets.xcassets in Resources */ = {{isa = PBXBuildFile; fileRef = {assets_fileref} /* Assets.xcassets */; }};')
lines.append(f'\t\t{preview_assets_buildfile} /* Preview Assets.xcassets in Resources */ = {{isa = PBXBuildFile; fileRef = {preview_assets_fileref} /* Preview Assets.xcassets */; }};')
for p in SUPABASE_PRODUCTS:
    lines.append(f'\t\t{supabase_framework_buildfiles[p]} /* {p} in Frameworks */ = {{isa = PBXBuildFile; productRef = {supabase_product_deps[p]} /* {p} */; }};')
lines.append("/* End PBXBuildFile section */\n")

# PBXFileReference
lines.append("/* Begin PBXFileReference section */")
for rp in swift_files:
    fr = file_refs[rp]
    name = os.path.basename(rp)
    lines.append(f'\t\t{fr} /* {name} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {quote(name)}; sourceTree = "<group>"; }};')
lines.append(f'\t\t{assets_fileref} /* Assets.xcassets */ = {{isa = PBXFileReference; lastKnownFileType = folder.assetcatalog; path = Assets.xcassets; sourceTree = "<group>"; }};')
lines.append(f'\t\t{preview_assets_fileref} /* Preview Assets.xcassets */ = {{isa = PBXFileReference; lastKnownFileType = folder.assetcatalog; path = "Preview Assets.xcassets"; sourceTree = "<group>"; }};')
lines.append(f'\t\t{infoplist_fileref} /* Info.plist */ = {{isa = PBXFileReference; lastKnownFileType = text.plist.xml; path = Info.plist; sourceTree = "<group>"; }};')
lines.append(f'\t\t{app_product_ref} /* {APP}.app */ = {{isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = {APP}.app; sourceTree = BUILT_PRODUCTS_DIR; }};')
lines.append("/* End PBXFileReference section */\n")

# PBXFrameworksBuildPhase
lines.append("/* Begin PBXFrameworksBuildPhase section */")
lines.append(f'\t\t{frameworks_phase} /* Frameworks */ = {{')
lines.append("\t\t\tisa = PBXFrameworksBuildPhase;")
lines.append("\t\t\tbuildActionMask = 2147483647;")
lines.append("\t\t\tfiles = (")
for p in SUPABASE_PRODUCTS:
    lines.append(f"\t\t\t\t{supabase_framework_buildfiles[p]} /* {p} in Frameworks */,")
lines.append("\t\t\t);")
lines.append("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
lines.append("\t\t};")
lines.append("/* End PBXFrameworksBuildPhase section */\n")

# PBXGroup
lines.append("/* Begin PBXGroup section */")

# Main
lines.append(f'\t\t{main_group} = {{')
lines.append("\t\t\tisa = PBXGroup;")
lines.append("\t\t\tchildren = (")
lines.append(f"\t\t\t\t{app_group} /* {APP} */,")
lines.append(f"\t\t\t\t{product_group} /* Products */,")
lines.append("\t\t\t);")
lines.append("\t\t\tsourceTree = \"<group>\";")
lines.append("\t\t};")

# Products
lines.append(f'\t\t{product_group} /* Products */ = {{')
lines.append("\t\t\tisa = PBXGroup;")
lines.append("\t\t\tchildren = (")
lines.append(f"\t\t\t\t{app_product_ref} /* {APP}.app */,")
lines.append("\t\t\t);")
lines.append("\t\t\tname = Products;")
lines.append("\t\t\tsourceTree = \"<group>\";")
lines.append("\t\t};")

# App group
lines.append(f'\t\t{app_group} /* {APP} */ = {{')
lines.append("\t\t\tisa = PBXGroup;")
lines.append("\t\t\tchildren = (")
for rp in root_files:
    lines.append(f"\t\t\t\t{file_refs[rp]} /* {os.path.basename(rp)} */,")
lines.append(f"\t\t\t\t{networking_group} /* Networking */,")
lines.append(f"\t\t\t\t{screens_group} /* Screens */,")
lines.append(f"\t\t\t\t{assets_fileref} /* Assets.xcassets */,")
lines.append(f"\t\t\t\t{preview_group} /* Preview Content */,")
lines.append(f"\t\t\t\t{infoplist_fileref} /* Info.plist */,")
lines.append("\t\t\t);")
lines.append(f"\t\t\tpath = {APP};")
lines.append("\t\t\tsourceTree = \"<group>\";")
lines.append("\t\t};")

# Networking group
lines.append(f'\t\t{networking_group} /* Networking */ = {{')
lines.append("\t\t\tisa = PBXGroup;")
lines.append("\t\t\tchildren = (")
for rp in networking_files:
    lines.append(f"\t\t\t\t{file_refs[rp]} /* {os.path.basename(rp)} */,")
lines.append(f"\t\t\t\t{networking_models_group} /* Models */,")
lines.append("\t\t\t);")
lines.append("\t\t\tpath = Networking;")
lines.append("\t\t\tsourceTree = \"<group>\";")
lines.append("\t\t};")

# Networking/Models group
lines.append(f'\t\t{networking_models_group} /* Models */ = {{')
lines.append("\t\t\tisa = PBXGroup;")
lines.append("\t\t\tchildren = (")
for rp in networking_models_files:
    lines.append(f"\t\t\t\t{file_refs[rp]} /* {os.path.basename(rp)} */,")
lines.append("\t\t\t);")
lines.append("\t\t\tpath = Models;")
lines.append("\t\t\tsourceTree = \"<group>\";")
lines.append("\t\t};")

# Screens group
lines.append(f'\t\t{screens_group} /* Screens */ = {{')
lines.append("\t\t\tisa = PBXGroup;")
lines.append("\t\t\tchildren = (")
for rp in screens_files:
    lines.append(f"\t\t\t\t{file_refs[rp]} /* {os.path.basename(rp)} */,")
lines.append(f"\t\t\t\t{onboarding_group} /* Onboarding */,")
lines.append("\t\t\t);")
lines.append("\t\t\tpath = Screens;")
lines.append("\t\t\tsourceTree = \"<group>\";")
lines.append("\t\t};")

# Onboarding group
lines.append(f'\t\t{onboarding_group} /* Onboarding */ = {{')
lines.append("\t\t\tisa = PBXGroup;")
lines.append("\t\t\tchildren = (")
for rp in onboarding_files:
    lines.append(f"\t\t\t\t{file_refs[rp]} /* {os.path.basename(rp)} */,")
lines.append("\t\t\t);")
lines.append("\t\t\tpath = Onboarding;")
lines.append("\t\t\tsourceTree = \"<group>\";")
lines.append("\t\t};")

# Preview Content group
lines.append(f'\t\t{preview_group} /* Preview Content */ = {{')
lines.append("\t\t\tisa = PBXGroup;")
lines.append("\t\t\tchildren = (")
lines.append(f"\t\t\t\t{preview_assets_fileref} /* Preview Assets.xcassets */,")
lines.append("\t\t\t);")
lines.append('\t\t\tpath = "Preview Content";')
lines.append("\t\t\tsourceTree = \"<group>\";")
lines.append("\t\t};")

lines.append("/* End PBXGroup section */\n")

# PBXNativeTarget
lines.append("/* Begin PBXNativeTarget section */")
lines.append(f'\t\t{app_target} /* {APP} */ = {{')
lines.append("\t\t\tisa = PBXNativeTarget;")
lines.append(f"\t\t\tbuildConfigurationList = {config_list_target};")
lines.append("\t\t\tbuildPhases = (")
lines.append(f"\t\t\t\t{sources_phase} /* Sources */,")
lines.append(f"\t\t\t\t{frameworks_phase} /* Frameworks */,")
lines.append(f"\t\t\t\t{resources_phase} /* Resources */,")
lines.append("\t\t\t);")
lines.append("\t\t\tbuildRules = ();")
lines.append("\t\t\tdependencies = ();")
lines.append(f"\t\t\tname = {APP};")
lines.append("\t\t\tpackageProductDependencies = (")
for p in SUPABASE_PRODUCTS:
    lines.append(f"\t\t\t\t{supabase_product_deps[p]} /* {p} */,")
lines.append("\t\t\t);")
lines.append(f"\t\t\tproductName = {APP};")
lines.append(f"\t\t\tproductReference = {app_product_ref};")
lines.append('\t\t\tproductType = "com.apple.product-type.application";')
lines.append("\t\t};")
lines.append("/* End PBXNativeTarget section */\n")

# PBXProject
lines.append("/* Begin PBXProject section */")
lines.append(f'\t\t{project_id} /* Project object */ = {{')
lines.append("\t\t\tisa = PBXProject;")
lines.append("\t\t\tattributes = {")
lines.append("\t\t\t\tBuildIndependentTargetsInParallel = 1;")
lines.append("\t\t\t\tLastSwiftUpdateCheck = 1600;")
lines.append("\t\t\t\tLastUpgradeCheck = 1600;")
lines.append("\t\t\t\tTargetAttributes = {")
lines.append(f"\t\t\t\t\t{app_target} = {{ CreatedOnToolsVersion = 16.0; }};")
lines.append("\t\t\t\t};")
lines.append("\t\t\t};")
lines.append(f"\t\t\tbuildConfigurationList = {config_list_project};")
lines.append('\t\t\tcompatibilityVersion = "Xcode 15.0";')
lines.append("\t\t\tdevelopmentRegion = en;")
lines.append("\t\t\thasScannedForEncodings = 0;")
lines.append("\t\t\tknownRegions = ( en, Base, );")
lines.append(f"\t\t\tmainGroup = {main_group};")
lines.append("\t\t\tpackageReferences = (")
lines.append(f"\t\t\t\t{supabase_pkg_ref} /* XCRemoteSwiftPackageReference \"supabase-swift\" */,")
lines.append("\t\t\t);")
lines.append(f"\t\t\tproductRefGroup = {product_group};")
lines.append('\t\t\tprojectDirPath = "";')
lines.append('\t\t\tprojectRoot = "";')
lines.append("\t\t\ttargets = (")
lines.append(f"\t\t\t\t{app_target} /* {APP} */,")
lines.append("\t\t\t);")
lines.append("\t\t};")
lines.append("/* End PBXProject section */\n")

# PBXResourcesBuildPhase
lines.append("/* Begin PBXResourcesBuildPhase section */")
lines.append(f'\t\t{resources_phase} /* Resources */ = {{')
lines.append("\t\t\tisa = PBXResourcesBuildPhase;")
lines.append("\t\t\tbuildActionMask = 2147483647;")
lines.append("\t\t\tfiles = (")
lines.append(f"\t\t\t\t{preview_assets_buildfile} /* Preview Assets.xcassets in Resources */,")
lines.append(f"\t\t\t\t{assets_buildfile} /* Assets.xcassets in Resources */,")
lines.append("\t\t\t);")
lines.append("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
lines.append("\t\t};")
lines.append("/* End PBXResourcesBuildPhase section */\n")

# PBXSourcesBuildPhase
lines.append("/* Begin PBXSourcesBuildPhase section */")
lines.append(f'\t\t{sources_phase} /* Sources */ = {{')
lines.append("\t\t\tisa = PBXSourcesBuildPhase;")
lines.append("\t\t\tbuildActionMask = 2147483647;")
lines.append("\t\t\tfiles = (")
for rp in swift_files:
    name = os.path.basename(rp)
    lines.append(f"\t\t\t\t{build_files[rp]} /* {name} in Sources */,")
lines.append("\t\t\t);")
lines.append("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
lines.append("\t\t};")
lines.append("/* End PBXSourcesBuildPhase section */\n")

# XCBuildConfiguration
def project_build_settings(is_debug):
    d = {
        "ALWAYS_SEARCH_USER_PATHS": "NO",
        "ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS": "YES",
        "CLANG_ANALYZER_NONNULL": "YES",
        "CLANG_ANALYZER_NUMBER_OBJECT_CONVERSION": "YES_AGGRESSIVE",
        "CLANG_CXX_LANGUAGE_STANDARD": '"gnu++20"',
        "CLANG_ENABLE_MODULES": "YES",
        "CLANG_ENABLE_OBJC_ARC": "YES",
        "CLANG_ENABLE_OBJC_WEAK": "YES",
        "CLANG_WARN_BLOCK_CAPTURE_AUTORELEASING": "YES",
        "CLANG_WARN_BOOL_CONVERSION": "YES",
        "CLANG_WARN_COMMA": "YES",
        "CLANG_WARN_CONSTANT_CONVERSION": "YES",
        "CLANG_WARN_DEPRECATED_OBJC_IMPLEMENTATIONS": "YES",
        "CLANG_WARN_DIRECT_OBJC_ISA_USAGE": "YES_ERROR",
        "CLANG_WARN_DOCUMENTATION_COMMENTS": "YES",
        "CLANG_WARN_EMPTY_BODY": "YES",
        "CLANG_WARN_ENUM_CONVERSION": "YES",
        "CLANG_WARN_INFINITE_RECURSION": "YES",
        "CLANG_WARN_INT_CONVERSION": "YES",
        "CLANG_WARN_NON_LITERAL_NULL_CONVERSION": "YES",
        "CLANG_WARN_OBJC_IMPLICIT_RETAIN_SELF": "YES",
        "CLANG_WARN_OBJC_LITERAL_CONVERSION": "YES",
        "CLANG_WARN_OBJC_ROOT_CLASS": "YES_ERROR",
        "CLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER": "YES",
        "CLANG_WARN_RANGE_LOOP_ANALYSIS": "YES",
        "CLANG_WARN_STRICT_PROTOTYPES": "YES",
        "CLANG_WARN_SUSPICIOUS_MOVE": "YES",
        "CLANG_WARN_UNGUARDED_AVAILABILITY": "YES_AGGRESSIVE",
        "CLANG_WARN_UNREACHABLE_CODE": "YES",
        "CLANG_WARN__DUPLICATE_METHOD_MATCH": "YES",
        "COPY_PHASE_STRIP": "NO",
        "ENABLE_STRICT_OBJC_MSGSEND": "YES",
        "ENABLE_USER_SCRIPT_SANDBOXING": "YES",
        "GCC_C_LANGUAGE_STANDARD": "gnu17",
        "GCC_NO_COMMON_BLOCKS": "YES",
        "GCC_WARN_64_TO_32_BIT_CONVERSION": "YES",
        "GCC_WARN_ABOUT_RETURN_TYPE": "YES_ERROR",
        "GCC_WARN_UNDECLARED_SELECTOR": "YES",
        "GCC_WARN_UNINITIALIZED_AUTOS": "YES_AGGRESSIVE",
        "GCC_WARN_UNUSED_FUNCTION": "YES",
        "GCC_WARN_UNUSED_VARIABLE": "YES",
        "IPHONEOS_DEPLOYMENT_TARGET": "17.0",
        "LOCALIZATION_PREFERS_STRING_CATALOGS": "YES",
        "MTL_FAST_MATH": "YES",
        "SDKROOT": "iphoneos",
        "SWIFT_EMIT_LOC_STRINGS": "YES",
        "SWIFT_VERSION": "5.0",
    }
    if is_debug:
        d.update({
            "DEBUG_INFORMATION_FORMAT": "dwarf",
            "ENABLE_TESTABILITY": "YES",
            "GCC_DYNAMIC_NO_PIC": "NO",
            "GCC_OPTIMIZATION_LEVEL": "0",
            "GCC_PREPROCESSOR_DEFINITIONS": '( "DEBUG=1", "$(inherited)", )',
            "MTL_ENABLE_DEBUG_INFO": "INCLUDE_SOURCE",
            "ONLY_ACTIVE_ARCH": "YES",
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS": '"DEBUG $(inherited)"',
            "SWIFT_OPTIMIZATION_LEVEL": '"-Onone"',
        })
    else:
        d.update({
            "DEBUG_INFORMATION_FORMAT": '"dwarf-with-dsym"',
            "ENABLE_NS_ASSERTIONS": "NO",
            "MTL_ENABLE_DEBUG_INFO": "NO",
            "SWIFT_COMPILATION_MODE": "wholemodule",
        })
    return d

def target_build_settings(is_debug):
    return {
        "ASSETCATALOG_COMPILER_APPICON_NAME": "AppIcon",
        "ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME": "AccentColor",
        "CODE_SIGN_STYLE": "Automatic",
        "CURRENT_PROJECT_VERSION": "1",
        "DEVELOPMENT_ASSET_PATHS": f'"\\"{APP}/Preview Content\\""',
        "ENABLE_PREVIEWS": "YES",
        "GENERATE_INFOPLIST_FILE": "NO",
        "INFOPLIST_FILE": f"{APP}/Info.plist",
        "INFOPLIST_KEY_UIApplicationSceneManifest_Generation": "YES",
        "INFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents": "YES",
        "INFOPLIST_KEY_UILaunchScreen_Generation": "YES",
        "INFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone": '"UIInterfaceOrientationPortrait"',
        "IPHONEOS_DEPLOYMENT_TARGET": "17.0",
        "LD_RUNPATH_SEARCH_PATHS": '( "$(inherited)", "@executable_path/Frameworks", )',
        "MARKETING_VERSION": "1.0",
        "PRODUCT_BUNDLE_IDENTIFIER": "com.trimrai.app",
        "PRODUCT_NAME": '"$(TARGET_NAME)"',
        "SWIFT_EMIT_LOC_STRINGS": "YES",
        "SWIFT_VERSION": "5.0",
        "TARGETED_DEVICE_FAMILY": '"1,2"',
    }

def emit_config(cid, name, settings):
    out = []
    out.append(f'\t\t{cid} /* {name} */ = {{')
    out.append("\t\t\tisa = XCBuildConfiguration;")
    out.append("\t\t\tbuildSettings = {")
    for k in sorted(settings.keys()):
        out.append(f"\t\t\t\t{k} = {settings[k]};")
    out.append("\t\t\t};")
    out.append(f"\t\t\tname = {name};")
    out.append("\t\t};")
    return out

lines.append("/* Begin XCBuildConfiguration section */")
lines.extend(emit_config(config_debug_project, "Debug", project_build_settings(True)))
lines.extend(emit_config(config_release_project, "Release", project_build_settings(False)))
lines.extend(emit_config(config_debug_target, "Debug", target_build_settings(True)))
lines.extend(emit_config(config_release_target, "Release", target_build_settings(False)))
lines.append("/* End XCBuildConfiguration section */\n")

# XCConfigurationList
lines.append("/* Begin XCConfigurationList section */")
lines.append(f'\t\t{config_list_project} = {{')
lines.append("\t\t\tisa = XCConfigurationList;")
lines.append("\t\t\tbuildConfigurations = (")
lines.append(f"\t\t\t\t{config_debug_project} /* Debug */,")
lines.append(f"\t\t\t\t{config_release_project} /* Release */,")
lines.append("\t\t\t);")
lines.append("\t\t\tdefaultConfigurationIsVisible = 0;")
lines.append("\t\t\tdefaultConfigurationName = Release;")
lines.append("\t\t};")
lines.append(f'\t\t{config_list_target} = {{')
lines.append("\t\t\tisa = XCConfigurationList;")
lines.append("\t\t\tbuildConfigurations = (")
lines.append(f"\t\t\t\t{config_debug_target} /* Debug */,")
lines.append(f"\t\t\t\t{config_release_target} /* Release */,")
lines.append("\t\t\t);")
lines.append("\t\t\tdefaultConfigurationIsVisible = 0;")
lines.append("\t\t\tdefaultConfigurationName = Release;")
lines.append("\t\t};")
lines.append("/* End XCConfigurationList section */\n")

# XCRemoteSwiftPackageReference
lines.append("/* Begin XCRemoteSwiftPackageReference section */")
lines.append(f'\t\t{supabase_pkg_ref} /* XCRemoteSwiftPackageReference "supabase-swift" */ = {{')
lines.append("\t\t\tisa = XCRemoteSwiftPackageReference;")
lines.append(f'\t\t\trepositoryURL = "{SUPABASE_REPO_URL}";')
lines.append("\t\t\trequirement = {")
lines.append("\t\t\t\tkind = upToNextMajorVersion;")
lines.append(f'\t\t\t\tminimumVersion = {SUPABASE_MIN_VERSION};')
lines.append("\t\t\t};")
lines.append("\t\t};")
lines.append("/* End XCRemoteSwiftPackageReference section */\n")

# XCSwiftPackageProductDependency
lines.append("/* Begin XCSwiftPackageProductDependency section */")
for p in SUPABASE_PRODUCTS:
    lines.append(f'\t\t{supabase_product_deps[p]} /* {p} */ = {{')
    lines.append("\t\t\tisa = XCSwiftPackageProductDependency;")
    lines.append(f"\t\t\tpackage = {supabase_pkg_ref} /* XCRemoteSwiftPackageReference \"supabase-swift\" */;")
    lines.append(f"\t\t\tproductName = {p};")
    lines.append("\t\t};")
lines.append("/* End XCSwiftPackageProductDependency section */\n")

lines.append("\t};")
lines.append(f"\trootObject = {project_id} /* Project object */;")
lines.append("}")

with open(os.path.join(ROOT, f"{APP}.xcodeproj", "project.pbxproj"), "w") as f:
    f.write("\n".join(lines) + "\n")

# workspace contents
ws_dir = os.path.join(ROOT, f"{APP}.xcodeproj", "project.xcworkspace")
os.makedirs(ws_dir, exist_ok=True)
with open(os.path.join(ws_dir, "contents.xcworkspacedata"), "w") as f:
    f.write('<?xml version="1.0" encoding="UTF-8"?>\n<Workspace version = "1.0">\n  <FileRef location = "self:"></FileRef>\n</Workspace>\n')

print(f"Generated pbxproj with {len(swift_files)} Swift files.")
for rp in swift_files: print("  ", rp)
