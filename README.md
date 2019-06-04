# Pure crystal tar archive reader

This shard makes you to read the TAR archive files(POSIX ustar format and some functions in GNUTAR fomat).

In this version, only following entry types are supported:

- Regular file (typeflag: `'\0'` or `'0'`)
- Hardlink (typeflag: `'1'`)
- Symlink (typeflag: `'2'`)
- Directory (typeflag: `'5'`)
- GNU long path name (typeflag: `'L'`)
- GNU long link name (typeflag: `'K'`)

Supports gzipped tar archive file.

## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     tarball:
       github: arcage/tarball.cr
   ```

2. Run `shards install`

## Usage

```crystal
require "tarball"

# Extracts all files in "archive.tar" to under the "data" directory.
Tarball.extract_all("archive.tar", "data")

Tarball.open("archive.tar") do |tar|

  # list of included file system objects.
  tar.filenames
  #=> ["dir/", "dir/file_name.txt", "dir/image.png"]

  # extract specific file to specific path.
  tar.extract_file("dir/file_name.txt", "other_name.txt")

  # write content data to IO object.
  tar.write_content("dir/file_name.txt", STDOUT)
end

# open gzipped tar archive
Tarball.open_gz("archive.tar.gz") do |tar|
  # ...
end
```

## Contributors

- [ʕ·ᴥ·ʔAKJ](https://github.com/arcage) - creator and maintainer
