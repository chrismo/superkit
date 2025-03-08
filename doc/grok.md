# grok

The grok function is a great choice for parsing text, but due to some gaps in
its documentation and some vague error messages, it can be difficult to use at
first.

The docs do helpfully encourage building out grok patterns incrementally, but
without knowing some of grok's gotchyas, this can be discouraging.

Let's demonstrate these starting with this example where we want to extract the
name out of this string:

```text
My name is: Muerte!
```

To start incrementally, I know I want to skip everything up past the colon, and
then extract the name minus the closing exclamation point. There's probably not
a predefined pattern that exists for this prefix regex, and/or I'm feeling lazy
enough right now to not go looking for one, and the regex is pretty simple.

So, I'll define my own pattern in the 3rd arg to grok to handle this:
```mdtest-command
zq -z '
  yield "My name is: Muerte!"  
  | grok("%{NAME_PREFIX}", this, "NAME_PREFIX .*: ")'
```
But right away this fails:
```mdtest-output
error({message:"grok(): value does not match pattern",on:"My name is: Muerte!"})
```

It's a simple regex, it seems like it's accurate, it's hard for me to see what's
wrong?

The regex is fine, in fact. The real reason this fails is that the capture
pattern is **missing a field name** in which to store the value, not that the
value doesn't match the pattern. A field name is required in each capture
pattern (_except ... it isn't. Not really. Keep reading._)

We probably made this mistake because we don't really want to capture "My name
is: " in a field of the record. But, no big deal, we can use the cut operator
later to remove it.

```mdtest-command
zq -z '
  yield "My name is: Muerte!"  
  | grok("%{NAME_PREFIX:prefix}", this, "NAME_PREFIX .*: ")'             
```
```mdtest-output
{prefix:"My name is: "}
```
                       
Success!

Also, the pre-release of `super` has a fix for the nameless capture pattern.

```mdtest-command
super -z -c '
  yield "My name is: Muerte!"  
  | grok("%{NAME_PREFIX}", this, "NAME_PREFIX .*: ")'
```
Since there aren't any errors, and no field names assigned, it nows returns any
empty record.
```mdtest-output
{}
```

For our next incremental step, let's capture the name. That's all that's left.
```mdtest-command
super -z -c '
  yield "My name is: Muerte!"  
  | grok("%{NAME_PREFIX:prefix}%{WORD:name}", this, "NAME_PREFIX .*: ")'
```
```mdtest-output
{prefix:"My name is: ",name:"Muerte"}
```
    
Success again! Ok, that wasn't so bad, but - it's a little arduous. It doesn't
feel like I'm getting to use the power of regex in a straightforward manner.

There are two grok undocumented "hacks" that can make a simple job like this
even simpler.

First, (as seen already with the unnamed capture pattern in `super`), not all
capture patterns need a field name as long as _**one**_ of them has a field
name. So we can reduce our last example to be this:

```mdtest-command
super -z -c '
  yield "My name is: Muerte!" 
  | grok("%{NAME_PREFIX}%{WORD:name}", this, "NAME_PREFIX .*: ")'
```
```mdtest-output
{name:"Muerte"}
```

Second, custom regex patterns can be _inlined_ into the pattern string without
being a custom named pattern in the 3rd argument at all!
                   
```mdtest-command
super -z -c '
  yield "My name is: Muerte!" 
  | grok(".*: %{WORD:name}", this)'
```
```mdtest-output
{name:"Muerte"}
```

Now that feels clean and simple!        

## Unit tests in codebase

```mdtest-command
super -z -c 'yield "1", "foo" | grok("%{INT}", this)' 
```
```mdtest-output
{}
error({message:"grok(): value does not match pattern",on:"foo"})
```

## as of versions

```mdtest-command
super --version
```
```mdtest-output
Version: v1.18.0-308-g4ffbd69f
```
_and zq 1.18_
```mdtest-command
zq --version
```
```mdtest-output
Version: v1.18.0
```
