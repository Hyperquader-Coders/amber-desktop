# MoSCoW

Prioritisation by **Must / Should / Could / Won't have** (the lower-case Os just make it
pronounceable). This is the **scope** document, and it holds only what is **still open**: an
item leaves this file the moment it ships. Nothing here records work done — `git log` is for
that.

An empty band means that band is finished, not that it was never populated.

## Must have

## Should have

- **Decide where `amberlin-settings` belongs in the suite.** The package is published and
  is the thing that chooses which model Amberlin loads, but nothing here refers to it:
  `Depends` is `ambrosia, copal, amberlin` and it appears in no field. Installing the
  suite therefore does not get you the model manager. `Recommends`, beside `kat800`, is
  the likely answer — but it is a decision about what the suite *is*, not a missing line,
  so make it deliberately.

## Could have

## Won't have (this time)
