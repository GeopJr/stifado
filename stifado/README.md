# stifado

```
STIFADO v0.1.1
Usage: stifado [arguments]
Examples:
    STIFADO_DB=mongodb://user:pass@0.0.0.0:27017 stifado
    stifado -d mongodb://user:pass@0.0.0.0:27017
    stifado --no-android
    stifado --no-desktop --no-split
    stifado -o ./bianries
    stifado -m eff
Arguments:
    -d DATABASE, --db=DATABASE       Database url
    -o OUTPUT, --out=OUTPUT          Binary destination
    -m MIRROR, --mirror=MIRROR       Use a mirror. Available: ["EFF", "CALYX"]
    -l LIMIT, --limit=LIMIT          Amount of *bytes* per part. Default: 5MB
    --locales=LOCALES                Locales to download seperated by a comma or 'ALL'. Default: en-US
    --no-overwrite                   Disable overwriting builds if they already exist
    --no-android                     Disable grabbing Android builds
    --no-desktop                     Disable grabbing Desktop builds
    --no-split                       Disable splitting binaries into parts
    -h, --help                       Shows this help
```
