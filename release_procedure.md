**@adamkrellenstein:**

- Update ChangeLog
- Update `lib/config.py`: `VERSION_*`
- Update `protocol_changes.json` (as necessary)
- Update `setup.py` (as necessary)
- Run test suite
- Tag and Sign Release
- Merge branch into both `master` and `develop`
- Rebase `gh-pages` to `master`
- Upload (signed) package to PyPi
	* `sudo python3 setup.py sdist build`
	<!-- * `sudo python3 setup.py bdist_wheel build`	# Does not work with `apsw` and `ethereum-serpent` installs. -->
	* `twine upload -s dist/$NEW_FILES`
- Write [Release Notes](https://github.com/CounterpartyXCP/counterparty-lib/releases)
- Update documentation (as appropriate)

**@ivanazuber:**:

- Post to [Official Forums](https://forums.counterparty.io/discussion/445/new-version-announcements-counterparty-and-counterpartyd), Skype, [Gitter](https://gitter.im/CounterpartyXCP)
- Post to social media
- SMS and mailing list notifications
