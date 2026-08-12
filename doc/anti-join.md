# Anti-Join

_Capturing slack conversation for now_

chrismo
  Mar 17th at 9:00 AM
why anti join and not outer join - https://superdb.org/docs/tutorials/join/#anti-join - I run across anti often enough when discussing them, but syntax-wise, I think outer is the term I've seen the most

superdb.orgsuperdb.org
Join
Join (178 kB)
https://superdb.org/docs/tutorials/join/#anti-join





3 replies


Phil
  Mar 17th at 10:33 AM
@chrismo
: I'm hearing your question as implying anti join and outer join are different names for the same thing, but my understanding is they're different kinds of join. Am I misunderstanding your question?


chrismo
  Mar 17th at 10:36 AM
I may not be entirely clear on the difference then if there is … (I do know historically doing certain kinds of joins on different platforms, sometimes in different places (WHERE vs. JOIN) can result in subtle differences in edge cases … but that’s not necessarily the same thing?)
But mostly the question is about the term - I’m not aware of any popular SQL product that uses anti as a keyword at all with joins, or as a differentiator from outer


Phil
  Mar 17th at 10:45 AM
Some of the nooks & crannies of SQL are still not yet merged with my DNA, so I do sometimes lean on ChatGPT to summarize this kind of thing. :slightly_smiling_face:  Just now it distilled it down to:
Outer Join: Includes all rows from one or both tables, even if there’s no match, filling non-matching rows with NULL.
Anti Join: Returns only the rows from the left table that have no match in the right table.
In another query I asked it if anti join is part of the SQL spec and it explained that, while lots of implementations have it, apparently the reason it's not in the spec is rationalized by the fact that the logical equivalent of what's usually called an anti join can be expressed as a regular JOIN with a filter like NOT EXISTS. Indeed, I can see that SQL in Postgres (which we aspire to be syntactically very close to over time) is like this, so I guess the fact we have anti join as an explicit thing is somewhat unique.
