# Cred - credentials manager

![Cover image](https://github.com/mtkld/cred/blob/master/front.jpg?raw=true)

_Figure: (New commands have been added since this image was created) Example of creating a vault file, adding a key-value pair, exiting interactive mode, and extracting the value on the commandline._

Bash script to easily and securely manage credentials. Data stored in key-value pairs in an encrypted vault file.

Credentials are not written unencrypted to disk at any point but only kept in memory.

> [!CAUTION]
> Be aware of your swap file if you use one.

Encrypted with `openssl enc -aes-256-cbc -pbkdf2 -iter "$iterations" -salt -pass pass:"$password"`

## Purpose

- Allow scripts easy and secure access to credentials. Example use case: my automated Linux installation script needs credentials at different steps of installation.

- Allow easy managment of credentials vault (Change, Read, Update, Delete).

- Enable more dynamic use of credentials by allowing keys to be executed as bash scripts (include a script as value of key) to which values of other keys can be passed as like {{MY_KEY}}. Thus, having opened the vault once, you get more flexibility as relevant wrapper script for deplyment can be included in the cred-file.

> [!NOTE]
> Currently x) opt is not supported in non-interactive mode.

## Intended use

Use interactive mode to manage vault.

Extract values at command line to use for piping etc.

Unlock vault by piping password or by interactively typing it.

## Interactive

Interactive terminal CRUD interface to alter key-value pairs and meta-data of vault file.

### Dependencies

`(e) edit` - requires `micro` text editor. Used to edit key's value in memory without writing to file on disk.

`(y) yank` - requires `xsel --clipboard`, to copy key's value to clipboard.

### Interface

```
     Commands to manage vault
──────────────────────────────────
 (s) set key
 (u) unset key
 (v) view keys
 (e) edit key's value
 (r) rename key
 (y) yank key to clipboard
 (g) generate password for key
 (x) execute key as bash script
──────────────────────────────────
 (i) iterations [10000] change
 (p) password change
──────────────────────────────────
 (h) help
 (w) write vault to disk
 (q) quit
──────────────────────────────────
```

> [!NOTE]
> Make sure to (w) write any change; values added, password change etc...

## Command Line Interface (CLI)

CLI interface to extract a value by key.

```bash
# Decrypt and echo the value of key1
cred -e key1 my-vault

# Alternatively, pipe the password directly:
echo "mypassword" | cred -e key1 my-vault
```

- The decrypted vault file is never written to file on disk but kept only in shell-variable (but be aware of your swap file settings if you have one).
- Value of a key is edited in an editor of your choice.

You can pipe password to `cred` to skip the prompt if using -e option with its required argument. You can not pipe password for interactive mode.

## Usage

```bash
Usage: ./cred [-e key] [-n] <vaultfile>
```

### Embedded and execute bash scripts

Create a key and edit it (e option) to include a bash script. The script can include other keys as {{KEY}}. When the key is executed, the script will be run with the values of the keys inserted.

Simple example where you have defined MY_ACCESS_KEY and MY_SECRET_KEY in the vault:

Lets say you set the key `cloud_download` with the following value:

````bash

# Example API Credentials
ACCESS_KEY="{{MY_ACCESS_KEY}}"
SECRET_KEY="{{MY_SECRET_KEY}}"

# Bucket and File Information
BUCKET_NAME="my-bucket"
FILE_NAME="my-file.txt"

# API Endpoint
URL="https://cloud-example.com/${BUCKET_NAME}/${FILE_NAME}"

# Authorization Header (Basic Authentication)
AUTH_HEADER="Authorization: ${ACCESS_KEY}:${SECRET_KEY}"

# Make the API call to download the file
curl -s -H "${AUTH_HEADER}" "${URL}" -o "${FILE_NAME}"

# Check if the file was downloaded successfully
if [[ $? -eq 0 ]]; then
    echo "File downloaded successfully: ${FILE_NAME}"
else
    echo "Failed to download the file."
fi
```

`cred` will replace `{{MY_ACCESS_KEY}}` and `{{MY_SECRET_KEY}}` with the values of the keys `MY_ACCESS_KEY` and `MY_SECRET_KEY` when the key `cloud_download` is executed with the `x` option.

### Options

- `-e <key>`
  Extracts the value of the specified key(s) from the vault.
  Multiple keys can be specified as a space-separated string, e.g., `-e "key1 key2"`.

- `-n`
  Creates a new vault file.

- `-h`
  Displays the help message with usage instructions and examples.

### Example use

```bash
# Create a new vault:
cred -n my-vault

# Open the vault interactively
cred my-vault

# Pipe a password and open the vault
echo "mypassword" | cred my-vault

# Extract the value of a specific key
cred -e key1 my-vault

# Extract values of multiple keys
cred -e "key1 key2 key3" my-vault

# Pipe a password and extract a specific key
echo "mypassword" | cred -e key1 my-vault

````
