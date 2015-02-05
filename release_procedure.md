**@adamkrellenstein:**

- Quality Assurance
- Update `CHANGELOG.md`
- Update `lib.config.py`: `VERSION_*`
- Update `protocol_changes.json` (if necessary)
- Update `setup.py`
- Update test suite (as necessary)
- Run test suite
- Update documentation (as appropriate).
- Tag and Sign Release
- Merge branch into both `master` and `develop`
- Rebase `gh-pages` to `master`
- Write [Release Notes](https://github.com/CounterpartyXCP/counterpartyd/releases)
- Upload (signed) package to PyPi
	* `sudo python3 setup.py sdist build`
	<!-- * `sudo python3 setup.py bdist_wheel build`	# Does not work with `apsw` and `ethereum-serpent` installs. -->
	* `twine upload -s dist/$NEW_FILES`

**@ivanazuber:**:

- Post to [Official Forums](https://forums.counterparty.io/discussion/445/new-version-announcements-counterparty-and-counterpartyd), Skype, [Gitter](https://gitter.im/CounterpartyXCP)
- Post to social media
- SMS and mailing list notifications
