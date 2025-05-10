# Steps to release a new version

1. Run `./Scripts/updateDependencies.sh` from the project's folder to update the gems and pods to the latest version.
2. Apply any code changes.
	- Verify that all changes have been logged to [Changelog.md](Changelog.md).
	- Verify that all tests passes.
3. Run `./Scripts/generateDocs.sh` from the project's folder to update the documentation.
4. Merge branch with master and push to origin.
5. Create a new tag for the commit, e.g. "1.2.3".

