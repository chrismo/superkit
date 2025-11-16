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
echo '
  {"InstanceId":"i-05b132aa000f0afa0",
   "InstanceType":"t4g.teeny",
   "LaunchTime":"2025-04-01T12:34:56+00:00",
   "PrivateIpAddress":"10.0.1.2"}
' > ec2s.json

read -r instance_id instance_type launch_time private_ip <<<"$(
  super -f line -c "
    [InstanceId,InstanceType,LaunchTime,PrivateIpAddress]
    | join(this, ' ')" zz-ec2.json
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
