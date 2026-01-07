# macOS Reflective Code Loader

A modified version of Apple's dyld that loads Mach-O binaries (dylibs and bundles) directly from memory without touching disk, supporting both legacy and modern binary formats.

## Features

- **In-Memory Loading**: Load dylibs and bundles directly from memory (no disk writes)
- **Modern Format Support**: Full support for `LC_DYLD_CHAINED_FIXUPS` (macOS 11+)
- **Legacy Format Support**: Traditional `LC_DYLD_INFO_ONLY` binaries
- **Unsigned Binary Support**: Operates in `UNSIGN_TOLERANT=1` mode
- **Go Runtime Support**: Properly initializes Go-compiled dylibs with argc/argv/envp
- **Objective-C Support**: Automatic selector registration for ObjC frameworks
- **Network Loading**: Download and load binaries from remote URLs
- **Pointer Authentication**: ARM64E PAC support for authenticated pointers

### Supported Binary Types

- `MH_DYLIB` - Dynamic libraries
- `MH_BUNDLE` - Loadable bundles

### Supported Fixup Formats

- **Chained Fixups** (modern):
  - `DYLD_CHAINED_PTR_ARM64E`
  - `DYLD_CHAINED_PTR_ARM64E_USERLAND`
  - `DYLD_CHAINED_PTR_ARM64E_USERLAND24`
  - `DYLD_CHAINED_PTR_64`
  - `DYLD_CHAINED_PTR_64_OFFSET`

- **Traditional Fixups** (legacy):
  - `LC_DYLD_INFO_ONLY` with compressed bind/rebase opcodes

## Building

### Prerequisites

- macOS 11.0+
- Xcode Command Line Tools
- ARM64 architecture (Apple Silicon)

### Build Instructions

```bash
# Build the loader library
cd loader/src
c++ -c -std=gnu++11 -arch arm64 -DUNSIGN_TOLERANT=1 -I../include -Wno-deprecated *.cpp
ar rcs libloader.a *.o
cp libloader.a ../build/
cp libloader.a ../../Distribute/

# Build the ReflectiveLoader executable
cd ../../ReflectiveLoader/build
cmake ..
make
```

The compiled binary will be at: `ReflectiveLoader/build/ReflectiveLoader`

## Usage

### Load from Local File

```bash
./ReflectiveLoader /path/to/library.dylib
```

### Load from Remote URL

```bash
./ReflectiveLoader https://example.com/library.dylib
```

### Example Output

```
macOS Reflective Code Loader
(supports: MH_DYLIB, MH_BUNDLE, with or without LC_DYLD_CHAINED_FIXUPS)

[+] loading from file...
    payload now in memory (size: 7987456), ready for loading/linking...

Press any key to continue...

Done! Library loaded successfully.
Process will keep running (Ctrl+C to exit)...
```

## Technical Details

### Architecture

The loader is based on Apple's dyld source code, modified to:

1. **Operate in isolation** - Uses custom `LinkContext` separate from system dyld
2. **Load from memory** - Maps segments from memory buffers instead of file descriptors
3. **Handle unsigned code** - Skips code signature validation
4. **Resolve dependencies** - Uses `ImageLoaderProxy` to resolve external symbols

### Key Components

- **`ImageLoaderMachO`** - Base class for Mach-O loading
- **`ImageLoaderMachOCompressed`** - Handles compressed fixup formats and chained fixups
- **`ImageLoaderProxy`** - Proxies external symbol lookups to system libraries
- **`dyld_stubs`** - Provides isolated LinkContext with proper environment setup

### Memory Layout

1. **Segment Mapping**: Each `LC_SEGMENT_64` is mapped to its preferred address + ASLR slide
2. **BSS Zero-Fill**: Uninitialized data sections are properly zeroed
3. **Fixup Application**:
   - Rebases: Adjust for ASLR slide
   - Binds: Resolve to external symbols
   - Chained: Walk pointer chains and apply fixups
4. **Initialization**: Runs constructors in dependency order

### Chained Fixups Implementation

The chained fixups parser (`doApplyFixups`) handles:

1. **Import Table Parsing**: Resolves symbol names and libraries
2. **Chain Walking**: Follows linked lists of fixup locations
3. **Rebase Handling**: Adjusts pointers for ASLR
4. **Bind Handling**: Links to external symbols with optional addends
5. **PAC Support**: Preserves ARM64E pointer authentication codes

### Go Runtime Support

For Go-compiled dylibs:

- Sets up `argc`/`argv`/`envp` from current process
- Populates `ProgramVars` structure
- Zero-fills BSS sections (`__DATA.__bss`, `__DATA.__noptrbss`)
- Allows Go runtime and goroutines to initialize properly

### Objective-C Support

For dylibs using Objective-C:

- Walks `__objc_selrefs` section
- Registers all selectors with runtime via `sel_registerName()`
- Updates references to canonical selector addresses
- Runs before `__mod_init_func` constructors

## Limitations

- **macOS only** - ARM64 architecture
- **No executables** - Cannot load `MH_EXECUTE` binaries
- **No code signing** - Loaded code runs unsigned
- **System dependencies** - External symbols resolved from system libraries
- **Single load** - No unloading support (no `dlclose` equivalent)

## Security Considerations

This tool is designed for:

- ✅ Security research and testing
- ✅ CTF competitions
- ✅ Authorized penetration testing
- ✅ Defensive security analysis
- ✅ Malware analysis (analysis only, not augmentation)

**Do not use for malicious purposes.**

## Project Structure

```
ReflectiveLoader/
├── loader/                    # Core dyld-based loader library
│   ├── src/                  # Implementation files
│   │   ├── ImageLoaderMachO.cpp
│   │   ├── ImageLoaderMachOCompressed.cpp
│   │   ├── ImageLoaderProxy.cpp
│   │   └── dyld_stubs.cpp
│   ├── include/              # Headers
│   └── build/                # Build output (libloader.a)
├── ReflectiveLoader/         # Test harness executable
│   ├── main.mm              # Entry point
│   └── build/               # Build output
└── Distribute/              # Distribution files
```

## References

- Apple dyld source: https://opensource.apple.com/source/dyld/
- Mach-O format: https://github.com/apple-oss-distributions/xnu
- Chained fixups: `<mach-o/fixup-chains.h>`

## License

Based on Apple's dyld source code (APSL 2.0). Modifications for research purposes.

## Author

Modified from Apple's dyld for security research and EDR evasion testing.
