# unnest

The `unnest` operator has this signature in the super docs:

```
unnest <expr> [ into ( <query> ) ]
```
                                  
The simple form of unnest is pretty straightforward, to loop over each value in
the `<expr>` array. In this simple example, we `collect` the values output by
`seq 1 3` into an array, and then `unnest` each value back out again.

```mdtest-command
seq 1 3 | super -s -c "
  collect(this)
  | unnest this
" -  
```
```mdtest-output
1
2
3
```

## unnest ... into examples

`unnest ... into` is a bit more complicated, esp. in the case of `<expr>` being
a two field record. The docs explain it like this:

> If `<expr>` is a record, it must have two fields of the form:
>
> `{<first>: <any>, <second>:<array>}`
>
> where `<first>` and `<second>` are arbitrary field names, `<any>` is any
SuperSQL value, and <array> is an array value. In this case, the derived
sequence has the form:
> ```
> {<first>: <any>, <second>:<elem0>}
> {<first>: <any>, <second>:<elem1>}
> ...
> ```

Let's expand on our previous example a bit. We collect the values 1,2,3 into an
array, as before then package that up as the values of both fields in a new
record.

```mdtest-command
seq 1 3 | super -s -c "
  collect(this)
  | {foo:this, bar:this}
  | unnest {foo, bar} into (
      -- for each value in the bar array, pass that value plus all of data each time
      values f'foo is {this.foo}, bar is {this.bar}'
    )
" -
```
```mdtest-output
"foo is [1,2,3], bar is 1"
"foo is [1,2,3], bar is 2"
"foo is [1,2,3], bar is 3"
```

You can see here, `foo` is the `<any>` value and so is passed in as-is, while
the inner `bar` value is each individual value in the array.

But what this means is we can actually do a pair of nested `unnest` loops, like
so: 

```mdtest-command
seq 1 3 | super -s -c "
  collect(this)
  | {foo:this, bar:this}
  | unnest {foo, bar} into (
      -- for each value in the bar array, pass that value plus all of data each time
      unnest {this.bar, this.foo} into (
        -- now, for each value in the foo array, pass that value plus the single value
        -- from the outer unnest
        values f'foo is {this.foo}, bar is {this.bar}'
      )
    )
" -
```
```mdtest-output
"foo is 1, bar is 1"
"foo is 2, bar is 1"
"foo is 3, bar is 1"
"foo is 1, bar is 2"
"foo is 2, bar is 2"
"foo is 3, bar is 2"
"foo is 1, bar is 3"
"foo is 2, bar is 3"
"foo is 3, bar is 3"
```

## as of versions

```mdtest-command
super --version
```
```mdtest-output
Version: v0.0.0-20250930170057-3b76fa645ee8
```
_and zq 1.18_
```mdtest-command
zq --version
```
```mdtest-output
Version: v1.18.0
```
