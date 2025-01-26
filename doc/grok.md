# grok
      
_as of super prerelease sha 910e11a7_

```mdtest-command
super --version
```
```mdtest-output
Version: v1.18.0-222-g55d99d3b
```

The grok function is a great choice for working with strings in a way that can
rival and surpass the use of more common tools like awk and sed, but with some
gaps in its documentation and some vague error messages can make it difficult
to realize.

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
super -z -c '
  yield "My name is: Muerte!"  
  | grok("%{NAME_PREFIX}", this, "NAME_PREFIX .*: ")'
```
But right away this fails:
```mdtest-output
error({message:"grok(): value does not match pattern",on:"My name is: Muerte!"})
```

It's a simple regex, it seems like it's accurate, it's hard for me to see what's
wrong?

The regex is, in fact, fine. The real reason this fails is that the capture
pattern is **missing a field name** in which to store the value, not that the
value doesn't match the pattern. A field name is required in each capture
pattern (_except ... it isn't. Not really. Keep reading._).

We probably made this mistake because we don't really want to capture "My name
is: " in a field of the record. But, no big deal, we can use the cut operator
later to remove it.

```mdtest-command
super -z -c '
  yield "My name is: Muerte!"  
  | grok("%{NAME_PREFIX:prefix}", this, "NAME_PREFIX .*: ")'             
```
```mdtest-output
{prefix:"My name is: "}
```
                       
Success! 

Next incremental step: the name. That's all that's left.
```mdtest-command
super -z -c '
  yield "My name is: Muerte!"  
  | grok("%{NAME_PREFIX:prefix}%{WORD:name}", this, "NAME_PREFIX .*: ")'
```
```mdtest-output
{prefix:"My name is: ",name:"Muerte"}
```
    
Success again! Ok, that wasn't so bad, but - it's a little arduous to be making
any claims that I couldn't do better with awk or sed or whatever.

There are two grok undocumented "hacks" that can make a simple job like this
even simpler.

First, not all capture patterns need a field name as long as _**one**_ of them
has a field name. So we can reduce our last example to be this:

```mdtest-command
super -z -c '
  yield "My name is: Muerte!" 
  | grok("%{NAME_PREFIX}%{WORD:name}", this, "NAME_PREFIX .*: ")'
```
```mdtest-output
{name:"Muerte"}
```
           
Of course, this won't work when building up incrementally, given the rule that
at least one capture pattern must be named.

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

But, again, if building up incrementally, just the inlined regex will result
in the vague error message:

```mdtest-command
super -z -c '
  yield "My name is: Muerte!" 
  | grok(".*: ", this)'
```
```mdtest-output
error({message:"grok(): value does not match pattern",on:"My name is: Muerte!"})
```
