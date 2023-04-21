# Now 

- toku bundle
    - refactor
    - actually link static libraries
    - gzip luac? 
    - tree shaking
    - parse requires in luac files
    - figure out dependencies in object files
    - parse lua syntax instead of pattern
      matching for require statements

- Publish updated version

- Template input/output
    - Single source dir: assume dest is dir
    - Single source file: assume dest is file
    - Multiple sources: assume dest is dir

- Generator interface 
    - toku files / --span exec md5sum
    - toku pipe --each exec wget --jobs 10
