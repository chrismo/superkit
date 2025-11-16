# Optimizing Sup Values into Bash Variables

[//]: # (TODO: THIS NEEDS THE FULL DOCUMENTATION TREATMENT) 

While you should try to push as much logic into SuperDB commands, inevitably you'll
need these values in variables in your language of choice.

A simple one of those — languages — is Bash. It can be a common pattern to then do
something like this:

```bash
echo '
  {"InstanceId":"i-05b132aa000f0afa0",
   "InstanceType":"t4g.teeny",
   "LaunchTime":"2025-04-01T12:34:56+00:00",
   "PrivateIpAddress":"10.0.1.2"}
' > ec2s.json

instance_id=$(super -f line -c "values InstanceId" ec2s.json)
instance_type=$(super -f line -c "values InstanceType" ec2s.json)
launch_time=$(super -f line -c "values LaunchTime" ec2s.json)
private_ip=$(super -f line -c "values PrivateIpAddress" ec2s.json)

echo "$instance_id" : "$instance_type" : "$launch_time" : "$private_ip"
```

But that just seems ... slow. And repetitive. How can we make this better?

If we can trust that there's no spaces in the data, we can do this:

```bash
read -r instance_id instance_type launch_time private_ip <<<"$(
  echo '
    {"InstanceId":"i-05b132aa000f0afa0",
     "InstanceType":"t4g.teeny",
     "LaunchTime":"2025-04-01T12:34:56+00:00",
     "PrivateIpAddress":"10.0.1.2"}
  ' |
    super -f line -c "
      [InstanceId,InstanceType,LaunchTime,PrivateIpAddress]
      | join(this, ' ')" - 
)"

echo "$instance_id" : "$instance_type" : "$launch_time" : "$private_ip"
```

The IFS env var controls how Bash splits strings and defaults to space, tab, and
newline. If we need tab-delimited output from super to support spaces in values,
we can do this:

```bash
IFS=$'\t' read -r name title <<<"$(
  echo '{"Name":"David Lloyd George","Title":"Prime Minister"}' |
    super -f line -c "[Name,Title] | join(this, '\t')" -
)"

echo "$title" : "$name"
```

If we want a simpler SuperDB command, just outputting the values as a separate
string each on its own line will require we handle that with `mapfile` into a
Bash array. Accessing the Bash array is still fast, and this approach is about
the equivalent in terms of time.

This version is more verbose on the Bash side of things, and is probably not
worth the simpler SuperDB command.

```bash
mapfile -t values <<<"$(
  echo '
    {"InstanceId":"i-05b132aa000f0afa0",
     "InstanceType":"t4g.teeny",
     "LaunchTime":"2025-04-01T12:34:56+00:00",
     "PrivateIpAddress":"10.0.1.2"}
  ' |
    super -f line -c "values InstanceId,InstanceType,LaunchTime,PrivateIpAddress" -
)"

instance_id="${values[0]}"
instance_type="${values[1]}"
launch_time="${values[2]}"
private_ip="${values[3]}"

echo "$instance_id" : "$instance_type" : "$launch_time" : "$private_ip"
```
                                                         
Except ...

### Empty Fields and IFS Whitespace

There's a flaw in space or tab-delimited options. If a field being returned is
*empty*, the multiple delimiters will be collapsed together, causing the reads.
                                     
```bash
IFS=$'\t' read -r a b c <<<"$(
  echo '{"a":"x","b":"","c":"z"}' |
    super -f line -c "
      values [this.a, this.b, this.c]
      | join(this, '\t')
    " -
)"

echo "$a" : "$b" : "$c"
# => x : z : 
```
                                                                      
"If the value of IFS consists solely of IFS whitespace, any sequence of IFS
whitespace characters delimits a field, so a field consists of characters that
are not unquoted IFS whitespace, and null fields result only from quoting.

If IFS contains a non-whitespace character, then any character in the value of
IFS that is not IFS whitespace, along with any adjacent IFS whitespace
characters, delimits a field. This means that adjacent non-IFS-whitespace
delimiters produce a null field. A sequence of IFS whitespace characters also
delimits a field.

Explicit null arguments ("" or '') are retained and passed to commands as empty
strings. Unquoted implicit null arguments, resulting from the expansion of
parameters that have no values, are removed. Expanding a parameter with no value
within double quotes produces a null field, which is retained and passed to a
command as an empty string."

-- https://www.gnu.org/software/bash/manual/bash.html#Word-Splitting-1

So, maybe we can put quotes around our values? While it does retain the empty
field, the quotes aren't stripped out of the values, which makes sense, but
isn't helpful here.

```bash
IFS=$'\t' read -r a b c <<<"$(
  echo '{"a":"x","b":"","c":"z"}' |
    super -f line -c "
      values [f'\"{this.a}\"', f'\"{this.b}\"', f'\"{this.c}\"']
      | join(this, '\t')
    " -
)"

echo "$a" : "$b" : "$c"
# => "x" : "" : "z"
```
                   
We should then be able to use a non-whitespace IFS to split the values, and
retain empty fields:

```bash
IFS='|' read -r a b c <<<"$(
  echo '{"a":"x","b":"","c":"z"}' |
    super -f line -c "values [a, b, c] | join(this, '|')" -
)"

echo "$a" : "$b" : "$c"
# => "x" : "" : "z"
```
