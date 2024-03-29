# TAR archive reader for Crystal

This shard makes you to read the TAR archive files(POSIX ustar format and some functions in GNUTAR fomat).

No external library needed. This is written in pure Crystal.

In this version, following entry types are supported:

- Regular file (typeflag: `'\0'` or `'0'`)
- Hardlink (typeflag: `'1'`)
- Symlink (typeflag: `'2'`)
- Directory (typeflag: `'5'`)
- PAX data (typeflag: `'x'`) (**mtime**, **path**, **linkpath**, **uid**, **gid**)
- GNU long path name (typeflag: `'L'`)
- GNU long link name (typeflag: `'K'`)

Other entry type will be extracted as a regular file.

Supporting gzipped tar archive file.

## Installation

Add the dependency to your `shard.yml`:

```yaml
dependencies:
  tarball:
    github: arcage/tarball.cr
```

Then, run `shards install`

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

## API Documents

- [http://www.denchu.org/tarball.cr/](http://www.denchu.org/tarball.cr/)

## Contributors

- [ʕ·ᴥ·ʔAKJ](https://github.com/arcage) - creator and maintainer
