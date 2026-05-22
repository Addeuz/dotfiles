Generate a concise MR description summarizing the changes on the current branch compared to a base branch.

The base branch to compare against is: $ARGUMENTS

If no base branch was provided, ask the user which branch to compare against before proceeding.

Steps:
1. Run `git log <base-branch>..HEAD --oneline` to see the commits on this branch.
2. Run `git diff <base-branch>..HEAD --stat` to get a high-level overview of changed files.
3. Run `git diff <base-branch>..HEAD` on the most significant files to understand what actually changed. Focus on logic changes, not just reformatting. Group related files together to understand the intent.
4. Write a brief, well-structured MR summary in plain prose (no bullet-point lists of file names). Organize it by logical area of change, not by file. Each section should explain *what* changed and *why*, as you understand it from the code.

Output only the MR summary text — ready to paste directly into a merge request description.
