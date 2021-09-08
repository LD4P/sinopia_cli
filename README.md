# sinopia_cli
Commandline Interface to Sinopia API

Note this only supports part of the Sinopia API. Additional support will be added as necessary.

## Usage
```
$ exe/sinopia-cli -h
Commands:
  sinopia-cli help [COMMAND]               # Describe available commands or one specific command
  sinopia-cli resource SUBCOMMAND ...ARGS  # commands for resources
```

### List resources
```
$ exe/sinopia-cli resource help list
Usage:
  sinopia-cli resource list

Options:
  [--uri-only], [--no-uri-only]              # Print resource URIs only.
  [--templates-only], [--no-templates-only]  # Resource templates only.
  [--group=GROUP]                            # Group name filter.
  [--updated-before=UPDATED_BEFORE]          # Resource last updated before filter, e.g., 2019-11-08T17:40:23.363Z
  [--updated-after=UPDATED_AFTER]            # Resource last updated after filter, e.g., 2019-11-08T17:40:23.363Z
  [--type=TYPE]                              # Class filter, e.g., http://id.loc.gov/ontologies/bibframe/AbbreviatedTitle
  [--api-url=API_URL]
                                             # Default: https://api.stage.sinopia.io
```

For example:
```
$ exe/sinopia-cli resource list --uri-only --group=stanford --templates-only
https://api.stage.sinopia.io/resource/zzzzzpcc:bf2:test:Instance
https://api.stage.sinopia.io/resource/zzzzzz_pcc:bf2:Monograph:Work
https://api.stage.sinopia.io/resource/pmo:bf2:kk:AgentSimplifiedPMO:RWO
...
```

Note the ability to return just the URIs (`--uri-only`) instead of the entire resource record.

### Delete resources
```
$ exe/sinopia-cli resource help delete
Usage:
  sinopia-cli resource delete

Options:
  [--uri=one two three]  # Space separated list of URIs.
  [--file=FILE]          # File containing list of URIs.
  [--token=TOKEN]        # JWT token. Otherwise, read from .cognitoToken
  [--api-url=API_URL]
                         # Default: https://api.stage.sinopia.io
```

For example:
```
$ exe/sinopia-cli resource delete --uri=https://api.development.sinopia.io/resource/e9a4c64a-0202-4d8b-a5ea-6785f15b2164
Deleted https://api.development.sinopia.io/resource/e9a4c64a-0202-4d8b-a5ea-6785f15b2164
```

Note the ability to delete from URIs listed in a file (`--file`).

## Authentication
Some methods (e.g., resource delete) require a JWT token. See [these instructions](https://github.com/LD4P/sinopia_api/blob/main/README.md#get-a-jwt) for obtaining a token.

The token can either be provided with `--token` or in a file named `.cognitoToken`.
