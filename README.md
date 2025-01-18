# Cred - credentials manager

![Cover image](https://github.com/mtkld/cred/blob/master/front.jpg?raw=true)

_Figure: (New commands have been added since this image was created) Example of creating a vault file, adding a key-value pair, exiting interactive mode, and extracting the value on the commandline._

Bash script to easily and securely manage credentials. Data stored in key-value pairs in an encrypted vault file.

Made to:

- Work in most live environments with widely available tools and Bash.
- Store all credentials in a single file for easy transfer and download
- Easy to integrate with other scripts (bash scripts can be included in vault file that when called inside `cred` will do whatever bash can do, for example set vualt-credentials as envirronment variables and call the other relevant scripts on the host system)
- Easy to integrate with cloud services (default save function can be overridden with own internal script to upload the vault file to a cloud service, and `cred` can open URL's as vault files)
- Easy to update and change cryptographic procedures (override encryption and decryption functions)
- Easy to update meta settings of the vault file (iterations, password etc...)
- Quality of life features to easily manage and update the key-value pairs in the vault file (interactive mode with CRUD operations)
- Secure editing of vault (all changes are written to file only when specific write command is invoked, similar to `fdisk`)
- Secure handling of decrypted content (only in memory, not on disk)
- Keep a history of modifications to the vualt.
- Provide options to pipe password to open vault and options to extract values from vault at command line.

> [!NOTE]
> This documentation is a work in progress.

> [!CAUTION]
> Decrypted content resides only in RAM-memory, not on disk. Howver, this is not designed to protect against serious attacks on the RAM-memory of the system. Ideally, decrypting content would stream it to `keyctl` with minimum exposure in memory. This is not implemented. An approach is to wipe variables after use, but successfull wipe is not a guarantee because of internal memory managment complexity of the system.

> [!CAUTION]
> Be aware of your swap file if you use one. Decrypted content resides only in RAM-memory, but swap file can be a risk.

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

> [!NOTE]
> Custom editor: You can set alternative editor by setting the variable USE_EDITOR, for example USE_EDITOR="nvim" at the top of the script.

> [!CAUTION]
> If you set a custom editor, it will use temp-files on disk to pass data between the editor and the script. (If you use the default editor `micro`, no data is written to disk).

`(y) yank` - requires `xsel --clipboard`, to copy key's value to clipboard.

### Why was `micro` chosen as editor?

The goal is to never write any unencrypted data to the disk. An editor which can recieve piped content and return it back to the shell via stdout is needed. Micro can do this. Edit the content and press `Ctrl+Q` to exit the editor and return the content to the shell.

`micro` is the only editor i found able to do this (had no success with N/Vim).

### Interface

```
     Commands to manage vault
─────────────────────────────────────
 (s) set key
 (u) unset key
 (v) view keys
 (e) edit key's value
 (r) rename key
 (y) yank key to clipboard
 (g) generate password for key
 (x) execute key as bash script
 (X) list bash scripts and exeucte
 (b) toggle base64 enc/dec for key
─────────────────────────────────────
 (m) key-marking mode
 (i) iterations [10000] change
 (p) password change
─────────────────────────────────────
 (?) help
 (I) additional info
 (w) write vault to disk
 (q) quit
─────────────────────────────────────
```

> [!NOTE]
> Make sure to (w) write any change; values added, password change etc...

### Options in interactive mode

Things to know

#### (X)

This option lists all keys that have a bash script as value. You can then choose to execute one.

For the bash script to be listed, it must start with `#!/bin/bash`

#### (m) - key-marking mode

Enter key-marking mode, the selected key remains till pressing `n`.

> [!TIP]
> This means you can purposefully avoid including `#!/bin/bash` in the script to avoid it being listed. It will execute the same, as it is passed to `eval` when executed.

#### (h)

Shows a key's history. Each time a key is modified, a copy of the previous value is saved in the history. You can view the history of a key with this option.

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

### Options

- `-e <key>`
  Extracts the value of the specified key(s) from the vault.
  Multiple keys can be specified as a space-separated string, e.g., `-e "key1 key2"`.

- `-n`
  Creates a new vault file.

  Desired password for vault can be piped.

- `-h`
  Displays the help message with usage instructions and examples.

#### Example use

````bash
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

``
## A note on remote files

`cred` can open vault files from remote locations. If the file path provided is a URL, `cred` will use `curl` to fetch the file.

Care was taken to pipe the output of `curl` to a variable and not to a temp file on disk.

```bash
content=$(curl -fSL "$file")
````

Thus, remote files only live in memory on the local host, even in encrypted mode.

## Other special keys

Create the key `__info` and its content will be printed when entering the vault and when `i` option in interactive mode is used.

Purppose: As you can write keys holding bash script to be executed, the `__info` key can be used to provide information about specific use cases.

## Custom options

You can define options of your own like '-u' or '--upload'. You just use them when calling `cred`.

```bash
cred --upload "some data related to upload" target-vault-file
```

This creates `__opt_upload` key in the vault file with the value "some data related to upload".

Then, `-u` will create `_opt_u` (note, only one underscore) and `--upload` will create `__opt_upload` (note, two underscores).

You can not create custom options for the existing ones `-e`, `-n`, `-h`.

> [!NOTE]
> This is used for custom functionality. Bash code that has been added to a key and is executed (the `x` option) can use data from custom options. Say you want to encrypt a directory and upload to a cloud service, you can pass the target dir at the command line like `cred -s "./source-directory" https://example-cloud.com/mystorage/my-vault-file`. There, -s is the custom option.

## Cred functions

Anu function available to cred (inculding overridden ones like `__ced` and `__cdd` that defines custom_encrypt_data and custom_decrypt_data, can be called from a key that is executed as a bash script.

Usefull for for example using the same custom encryption and decryption functions in, say, a script that uploads the vault file to a cloud service and wants to encrypt it first.

## Note on history

When editing a key's value (e option) history is saved as a `diff` between old and new value of key. Intended to save less data when editing for example scripts internal to the vault.

Setting keys (s option) does not save diff history, as no lengthy content is expected to be modified this way.

## Overriding encryption and decryption functionality

The default encryption and decryption functionality can be updated by creating the key `__ced` and `__cdd` respectively. These stand for "custom encrypt data" and "custom decrypt data".

The purpose is the be able to easily update the cryptographic procedure.

`__ccv` - Custom crypto version, update this to keep track of when you change the encryption and decryption functions.

The custom crypto version number is stored in the cred file, and you can store it in any other encrypted file you generate (like if you have a script in `cred` that packages a directory and uploads to a cloud.

> [!TIP]
> Each time you change the custom cryptography functions, update the `__ccv` key to keep track of the version. Store the previous version number along with the previous functions, in case you later find data encrypted with a previous version. This is important because for example if you use Argon2, you will have defined specific parameters that must be the same to decrypt.

> [!CAUTION]
> I am no cryptography expert. After some superficial research, CBC, HMAC and Argon2 seemed a good choice. CBC over GCM because openssl didnt have enough support, and [this](https://security.stackexchange.com/a/184307) from [here](https://security.stackexchange.com/questions/184305/why-would-i-ever-use-aes-256-cbc-if-aes-256-gcm-is-more-secure).

> [!WARNING]
> If you override these, ensure to test on a test-vaul file first. Onec they work, open the target vault, add or update `__ced` and `__cdd` keys with the new functions. Then, writing the vault back to the file, will encrypt the data with the new fucntion.

The functions must be defined as functions, and must return the encrypted or decrypted data.

> [!NOTE]
> As you can see in the encrypt example, we need to store salt, iv etc. We serialize an associative array with all parameters and the encrypted data. Because we write also the callback for decrypting, we know how to unpack it. `cred` doesn't care about what the encrypt function return, it only stores in the file what is returned, and then sends it to the decrypt function on opening the vault.

> [!WARNING]
> Be aware of the iterations parameter. If your previous encryption was PBKDF2 with 10000 iterations, and you set `__ced` and `__cdd` to CBC+HMAC+Argon2 while keeping 10000 iterations, the cryptographic operations will take very long time.

> ! [!NOTE]
> The option to test iteration-time will test with `__ced` if such is set, instead of with default PBKDF2-approach. This is useful to see how long time the new approach will take. Start testing with low iteration count, and increase until you find a suitable value.

### Example of custom encryption function

> [!NOTE]
> There is an extended example further down.

```bash
custom_encrypt_data() {
  data="$1"
  password="$2"
  iter="$3"

  # Generate random values
  salt=$(openssl rand -base64 16)

  iv=$(openssl rand -hex 16)

  hmac_key=$(openssl rand -hex 32)

  # Derive key using Argon2 and extract the hash portion
  encoded_key=$(echo -n "$password" | argon2 "$salt" -id -t "$iter" -m 16 -p 2 -l 32 | grep -oP '(?<=Encoded:).*' | xargs)

  # Extract the actual Base64-encoded hash (last segment)
  base64_hash=$(echo "$encoded_key" | awk -F'$' '{print $NF}')

  # Decode Base64-encoded hash into hexadecimal
  key=$(echo "$base64_hash" | base64 -d | xxd -p -c 256)

  # Encrypt the data and Base64 encode the result
  encrypted=$(echo -n "$data" | openssl enc -aes-256-cbc -K "$key" -iv "$iv" -e | base64 -w 0)

  # Generate HMAC
  hmac=$(echo -n "$encrypted" | openssl dgst -sha256 -mac HMAC -macopt hexkey:$hmac_key | awk '{print $2}')

  # Create an associative array
  declare -A encryption_result
  encryption_result["salt"]=$salt
  encryption_result["iv"]=$iv
  encryption_result["encrypted_data"]=$encrypted
  encryption_result["hmac"]=$hmac
  encryption_result["hmac_key"]=$hmac_key

  # Serialize and return the array
  echo -n $(declare -p encryption_result)
}
```

### Example of custom decryption function

> [!NOTE]
> There is an extended example further down.

```bash
custom_decrypt_data() {
  serialized_data="$1"
  password="$2"
  iter="$3"

  # Deserialize the serialized array
  eval "$(echo "$serialized_data")"

  # Extract values from the associative array
  salt="${encryption_result["salt"]}"
  iv="${encryption_result["iv"]}"
  encrypted="${encryption_result["encrypted_data"]}"
  hmac="${encryption_result["hmac"]}"
  hmac_key="${encryption_result["hmac_key"]}"

  # Derive the encryption key using Argon2 and extract the hash portion
  encoded_key=$(echo -n "$password" | argon2 "$salt" -id -t "$iter" -m 16 -p 2 -l 32 | grep -oP '(?<=Encoded:).*' | xargs)

  # Extract the actual Base64-encoded hash (last segment)
  base64_hash=$(echo "$encoded_key" | awk -F'$' '{print $NF}')

  # Decode Base64-encoded hash into hexadecimal
  key=$(echo "$base64_hash" | base64 -d | xxd -p -c 256)

  # Validate the HMAC
  calculated_hmac=$(echo -n "$encrypted" | openssl dgst -sha256 -mac HMAC -macopt hexkey:$hmac_key | awk '{print $2}')
  if [[ "$calculated_hmac" != "$hmac" ]]; then
    echo "Error: HMAC validation failed. Data integrity compromised."
    return 1
  fi

  # Decode Base64 and decrypt the data
  decrypted=$(echo -n "$encrypted" | base64 -d | openssl enc -aes-256-cbc -K "$key" -iv "$iv" -d)

  # Output the decrypted data
  echo -n "$decrypted"
}

```

## Overriding write functionality

Create the key `__write` and add bash script (the script itself, not a path to a script) as value.

The bash script will have access to

- `__data_file_path` - path as given at the command line to `cred` (example: `cred my-vault` or `cred /home/user/my-vault` or `cred https://my-cloud.com/my-vault`).
- `__data_file_name` - name of the vault file (example: `my-vault`).
- `__data_file_content` - the content in vault-format as it will be written to the disk.

Use them in the script by enclosing them in double curly braces, like `{{__data_file_path}}`.

> [!IMPORTANT]
> The script must return 0 on success and non-zero on failure. So do 'exit 0' or 'exit 1' at the end of the script. Saving happens on 0 return.

### Example overriding write functionality

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
> The example presumes these two keys exist in the vault file: `B2CTL_INMYVAULT_APP_KEY` and `B2CTL_INMYVAULT_ENTRYBUCKET_KEY_ID`

> [!NOTE]
> b2ctl accepts piped data, thus allowing me to avoid writing the content to temp file.

## Embedded and execute bash scripts

There are 2 ways of including values from the vault in a bash script that exist in a key.

1. Create a key and edit it (e option) to include a bash script. The script can include other keys as {{KEY}}. When the key is executed, the script will be run with the values of the keys inserted.
2. Every key in the vault is exported as vault\_[key name] and can be used directly in a bash script.

> [!TIP]
> The key that is eval:ed as can change values of keys in the vault, by using vault\_[key name] as variable names. Example: `vault_mykey="new value"`.

### Example of inserting values into a bash script

Simple example where you have defined MY_ACCESS_KEY and MY_SECRET_KEY in the vault:

Lets say you set the key `cloud_download` with the following bash script as value:

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

## Extended example of custom encryption and decryption functions

```bash
#!/bin/bash

custom_encrypt_data() {
	data="$1"
	password="$2"
	iter="$3"
	output_file="$4"

	# If the fourth argument is not set, default to $data.enc
	if [[ -z "$output_file" && -f "$data" ]]; then
		output_file="${data}.enc"
	fi

	# Generate random values
	salt=$(openssl rand -base64 16)
	iv=$(openssl rand -hex 16)
	hmac_key=$(openssl rand -hex 32)

	# Derive key using Argon2 and extract the hash portion
	encoded_key=$(echo -n "$password" | argon2 "$salt" -id -t "$iter" -m 16 -p 2 -l 32 | grep -oP '(?<=Encoded:).*' | xargs)

	# Extract the actual Base64-encoded hash (last segment)
	base64_hash=$(echo "$encoded_key" | awk -F'$' '{print $NF}')

	# Because the Base64 encoding is not padded from argon
	# we need to add the correct padding for older versions of base64, like 9.3
	# Calculate the missing padding
	padding=$(((4 - (${#base64_hash} % 4)) % 4))

	# Add the correct number of '=' padding characters
	base64_hash="${base64_hash}$(printf '=%.0s' $(seq 1 $padding))"

	# Decode Base64-encoded hash into hexadecimal
	key=$(echo "$base64_hash" | base64 -d | xxd -p -c 256)

	if [[ -f "$data" ]]; then
		# Set output file
		output_file="${data}.enc"

		# Pack metadata into a binary format (salt, iv, hmac_key)
		{
			printf "%-24s" "$salt"     # 24 bytes for salt (base64)
			printf "%-32s" "$iv"       # 32 bytes for IV (hex)
			printf "%-64s" "$hmac_key" # 64 bytes for HMAC key (hex)
			openssl enc -aes-256-cbc -K "$key" -iv "$iv" -e -in "$data"
		} >"$output_file"

		echo "File encrypted with embedded metadata: $output_file"
	else
		# For raw data, proceed as before
		encrypted=$(echo -n "$data" | openssl enc -aes-256-cbc -K "$key" -iv "$iv" -e | base64 -w 0)

		# Generate HMAC
		hmac=$(echo -n "$encrypted" | openssl dgst -sha256 -mac HMAC -macopt hexkey:$hmac_key | awk '{print $2}')

		# Create an associative array
		declare -A encryption_result
		encryption_result["salt"]=$salt
		encryption_result["iv"]=$iv
		encryption_result["encrypted_data"]=$encrypted
		encryption_result["hmac"]=$hmac
		encryption_result["hmac_key"]=$hmac_key

		# Serialize and return the array
		echo -n $(declare -p encryption_result)
	fi
}

```

```bash
#!/bin/bash
custom_decrypt_data() {
	data="$1"
	password="$2"
	iter="$3"
	output_file="$4"

	# If the fourth argument is not set, default to $data.enc
	if [[ -z "$output_file" && -f "$data" ]]; then
		output_file="${data}.dec"
	fi

	if [[ -f "$data" ]]; then
		# File decryption mode
		input_file="$data"

		# Extract metadata (salt, iv, hmac_key)
		salt=$(head -c 24 "$input_file" | tr -d ' ')
		iv=$(dd if="$input_file" bs=1 skip=24 count=32 2>/dev/null | tr -d ' ')
		hmac_key=$(dd if="$input_file" bs=1 skip=56 count=64 2>/dev/null | tr -d ' ')

		# Derive the encryption key using Argon2
		encoded_key=$(echo -n "$password" | argon2 "$salt" -id -t "$iter" -m 16 -p 2 -l 32 | grep -oP '(?<=Encoded:).*' | xargs)
		base64_hash=$(echo "$encoded_key" | awk -F'$' '{print $NF}')

		# Correct Base64 padding
		padding=$(((4 - (${#base64_hash} % 4)) % 4))
		base64_hash="${base64_hash}$(printf '=%.0s' $(seq 1 $padding))"

		# Decode Base64-encoded hash into hexadecimal
		key=$(echo "$base64_hash" | base64 -d | xxd -p -c 256)

		# Decrypt the file
		#encrypted_data=$(dd if="$input_file" bs=1 skip=120 2>/dev/null)
		#echo -n "$encrypted_data" | openssl enc -aes-256-cbc -K "$key" -iv "$iv" -d > "$output_file"

        # Use command substitution as bash can not handle binary data

		openssl enc -aes-256-cbc -K "$key" -iv "$iv" -d -in <(dd if="$input_file" bs=1 skip=120 2>/dev/null) >"$output_file"

	else
		# Raw data decryption mode
		serialized_data="$data"

		# Deserialize the serialized array
		eval "$(echo "$serialized_data")"

		# Extract values from the associative array
		salt="${encryption_result["salt"]}"
		iv="${encryption_result["iv"]}"
		encrypted="${encryption_result["encrypted_data"]}"
		hmac="${encryption_result["hmac"]}"
		hmac_key="${encryption_result["hmac_key"]}"

		# Derive the encryption key using Argon2
		encoded_key=$(echo -n "$password" | argon2 "$salt" -id -t "$iter" -m 16 -p 2 -l 32 | grep -oP '(?<=Encoded:).*' | xargs)
		base64_hash=$(echo "$encoded_key" | awk -F'$' '{print $NF}')

		# Correct Base64 padding
		padding=$(((4 - (${#base64_hash} % 4)) % 4))
		base64_hash="${base64_hash}$(printf '=%.0s' $(seq 1 $padding))"

		# Decode Base64-encoded hash into hexadecimal
		key=$(echo "$base64_hash" | base64 -d | xxd -p -c 256)

		# Validate the HMAC
		calculated_hmac=$(echo -n "$encrypted" | openssl dgst -sha256 -mac HMAC -macopt hexkey:$hmac_key | awk '{print $2}')
		if [[ "$calculated_hmac" != "$hmac" ]]; then
			echo "Error: HMAC validation failed. Data integrity compromised."
			return 1
		fi

		# Decrypt the raw data
		decrypted=$(echo -n "$encrypted" | base64 -d | openssl enc -aes-256-cbc -K "$key" -iv "$iv" -d)

		# Output the decrypted data
		echo -n "$decrypted"
	fi
}
```
