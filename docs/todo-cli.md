# Now 

- Split to separate project entirely

- toku cli help info and args table fixes
    - toku template -h shows "-l --load <load>"
      when it should be like "-l --load <module>"
    - consider parsed args should include
      arg.module instead of arg.load?
    - argparse doesn't seem to handle arguments
      that contain hyphens - how do we get
      around this for:
        - toku template -e CFLAGS "-a -b -c"
        - ...which fails due to argparse
          attempting to parse "-a -b -c"

- toku bundle
    - allow dynamic or static linking of lualib
    - refactor
    - gzip luac? 
    - tree shaking
    - parse lua syntax instead of pattern
      matching for require statements
    - test cases for emscripten, native static,
      and native dynamic

- Publish updated version

# Eventually

- Generator interface 
    - toku files / --span exec md5sum
    - toku pipe --each exec wget --jobs 10
