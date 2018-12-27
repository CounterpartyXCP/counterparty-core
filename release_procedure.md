**Development team:**

- Merge pending dev branches into `develop`
- Update `ChangeLog.md`
- Update `VERSION_` variables in `lib/config.py`
- Update `protocol_changes.json` (as necessary)
- Create `develop` PR to merge into `master` for final dev team review
- Make sure all PR CI test runners pass
- Merge PR into `master`
- Tag and Sign Release (for release notes, use the relevant text from `ChangeLog.md`)
- Rebase `gh-pages` to `master`
- Upload (signed) package to PyPi
	* `sudo python3 setup.py sdist build`
	* `sudo python3 setup.py sdist upload -r pypi`
- Update documentation (as appropriate)

**Announce:**:

- Post to [Official Forums](https://counterpartytalk.org/t/new-version-announcements-counterparty-and-counterpartyd/363)) and Slack
- Send emails on Dev announcement mailing list, main mailing list 
- Post to social media: Facebook, Twitter, etc.
