# Lunch Loop

app where students vote on what they want for lunch and check the school menu.

## what it does

- shows today's lunch with photos, calories and diet tags
- scroll back to see what was served on any past day
- vote every school day. each vote closes at 10 pm and picks the lunch for a week later
- you can see results and what you picked on old votes
- pick your wake county high school when you sign up

## running it

open `Untitled Project.xcodeproj` in xcode and run it on an iphone simulator (ios 26).

or open `LunchLoop.swiftpm` in swift playgrounds.

the menu and votes are fake data for now. `LunchService.swift` is where a real server would plug in.

food photo credits are in `CREDITS.md`.
