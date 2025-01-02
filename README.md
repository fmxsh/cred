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

### Why was `micro` chosen as editor?

The goal is to never write any unencrypted data to the disk. An editor which can recieve piped content and return it back to the shell via stdout is needed. Micro can do this. Edit the content and press `Ctrl+Q` to exit the editor and return the content to the shell.

`micro` is the only editor i found able to do this (had no success with N/Vim).

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

## A note on remote files

`cred` can open vault files from remote locations. If the file path provided is a URL, `cred` will use `curl` to fetch the file.

Care was taken to pipe the output of `curl` to a variable and not to a temp file on disk.

```bash
content=$(curl -fSL "$file")
```

Thus, remote files only live in memory on the local host, even in encrypted mode.

## Overriding write functionality

Create the key `__write` and add bash script (the script itself, not a path to a script) as value.

The bash script will have access to

- `__data_file_path` - path as given at the command line to `cred` (example: `cred my-vault` or `cred /home/user/my-vault` or `cred https://my-cloud.com/my-vault`).
- `__data_file_name` - name of the vault file (example: `my-vault`).
- `__data_file_content` - the content in vault-format as it will be written to the disk.

Use them in the script by enclosing them in double curly braces, like `{{__data_file_path}}`.

### Example overwriting write functionality

To illustrate the usefullness of this feature, here is an example of my own use:

Let'say we open the vault from a remote cloud location (with web address). It is easy, as `cred` just checks if the file path you provide is a URL and if so, uses `curl` to get the file.

```bash
> cred https://f003.backblazeb2.com/file/my-bucket/the-cred-file
```

But how do we save the file back to the cloud? We can not rely on a generic curl operation. We need specifc logic to authenticate against the cloud API and use specific API operations to upload the file.

The additional logic needed to save the file back to the cloud can be added to the `__write` key in the vault.

```bash
# First check what file we try to save
if [[ "{{__data_file_path}}" == "https://f003.backblazeb2.com/file/my-bucket/the-cred-file" ]]; then

    # Knowing the file, we know how and where to upload it
    # I use b2ctl to upload to Backblaze B2
    # It requires 2 environment variables to be set
	export B2CTL_APP_KEY="{{B2CTL_INMYVAULT_APP_KEY}}"
	export B2CTL_KEY_ID="{{B2CTL_INMYVAULT_ENTRYBUCKET_KEY_ID}}"

    # Upload the file
    # The content to be saved is piped to b2ctl which is capable of uploading to Backblaze B2
	echo -n "{{__data_file_content}}" | b2ctl --up {{__data_file_name}}
else
	echo "The variable does not equal the string."
fi
```

When writing (with the w-command), because `__write` key exists and is set to the above, the file content will be uploaded, given that the current open file is: https://f003.backblazeb2.com/file/my-bucket/the-cred-file

A generic solution for any blackblaze file could of course be made, as well as adding checks and support for other cloud services. Remember that this saving-logic is stored in the cred file itself, and usually one credfile is stored only in one dedicated location, whereas the logic above is enough. The beauty of this is that you could easily store the same cred-file onto a second location for backup, so at each save, both locations are updated.

> [!NOTE]
> The example presumes these two keys exist in the vault file `B2CTL_INMYVAULT_APP_KEY` and `B2CTL_INMYVAULT_ENTRYBUCKET_KEY_ID`

> [!NOTE]
> b2ctl accepts piped data, thus allowing me to avoid writing the content to temp file.

### Embedded and execute bash scripts

Create a key and edit it (e option) to include a bash script. The script can include other keys as {{KEY}}. When the key is executed, the script will be run with the values of the keys inserted.

Simple example where you have defined MY_ACCESS_KEY and MY_SECRET_KEY in the vault:

Lets say you set the key `cloud_download` with the following value:

```bash

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

```
