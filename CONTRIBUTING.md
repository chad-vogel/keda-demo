# Contributing to the KEDA Demo

Thanks for your interest in improving this demo! Contributions of all kinds are welcome—whether you want to fix typos, enhance the presentation material, or extend the automation scripts.

## How to Contribute

1. **Ask questions or share ideas**  
   - Use the repository’s GitHub Issues to raise questions, propose new topics, or report problems you encounter.
2. **Open an issue**  
   - Before starting substantial work, please open an issue describing the change. This helps others understand what you’re tackling and avoids duplicated effort.
3. **Submit a pull request (PR)**  
   - Fork the repo (or create a branch if you have write access).  
   - Make your changes in a topic branch (`feature/<short-description>`).  
   - Include clear commit messages and, when helpful, screenshots or diagrams showing what changed.  
   - Open a pull request against `main`, linking to any relevant issues. Explain the motivation behind the change and call out anything you would like reviewers to focus on.
4. **Run the test suite**  
   - Execute `dotnet test` from the repository root before submitting your PR. The tests cover the helper services and workloads using xUnit, FluentAssertions 7.x, and Moq.

## Contribution Ideas

- Improve or add slides under `docs/presentation/`.
- Expand the demo automation scripts or add new sample workloads.
- Share troubleshooting tips or lessons learned from running the demo in different environments.
- Enhance the documentation for setup, architecture, or reference operations.

## Code and Documentation Style

- Keep Markdown files readable—use headings, lists, and links to help others navigate the content.
- Where possible, use the existing folder structure (`docs/`, `manifests/`, `scripts/`) so changes are easy to find.
- Follow the project’s existing formatting conventions. Scripts are written for `bash`; sample code targets .NET 9.

## Getting Help

If you are unsure how to get started:

- Browse existing issues to see ongoing discussions.
- Open a new issue with your question; maintainers and the community will do their best to help.
- Feel free to open a draft pull request to gather early feedback on work in progress.

Thanks again for helping make this demo more useful for everyone!
