# Cred - credentials manager

![Cover image](https://github.com/mtkld/cred/blob/master/front.jpg?raw=true)

Bash script to easily and securely manage credentials. Data stored in key-value pairs in an encrypted vault file.

Credentials are not written unencrypted to disk at any point but only kept in memory (be aware of your swap file if you use one).

Encrypted with `openssl enc -aes-256-cbc -pbkdf2 -iter "$iterations" -salt -pass pass:"$password"`

## Purpose

- Allow scripts easy and secure access to credentials. Example use case: my automated Linux installation script needs credentials at different steps of installation.

- Allow easy managment of credentials vault (Change, Read, Update, Delete).

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
──────────────────────────────────
 (i) iterations [10000] change
 (p) password change
──────────────────────────────────
 (h) help
 (w) write vault to disk
 (q) quit
──────────────────────────────────
```

[!NOTE] Make sure to (w) write any change; values added, password change etc...

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
